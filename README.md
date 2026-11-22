# P2D

Aventura de plataformas 2D desenvolvida em Godot 4 para a unidade curricular de
**Projeto de Jogo 2D** (Mestrado em Desenvolvimento de Jogos Digitais, Universidade de Aveiro).
Tema: *Destroy Yourself*. Título por decidir.

Uma alma sem passado acorda no inferno apenas com o nome e tem de subir sete níveis, um por pecado
capital, sem poder atacar. Cada demónio oferece-lhe um atalho, e o jogo regista o que o jogador
aceita. A alma só diz o que o jogador escolhe, para que as escolhas sejam dele e não de uma
personagem já definida.

> **Estado:** a personagem jogável já anda, salta e tem controlo no ar, desliza nas paredes e salta
> delas, e o salto tolera pedidos ligeiramente fora de tempo. O jogo abre num menu principal, que dá
> acesso à sala de teste, ao nível 1 e à sala de treino, e tem pausa e opções gravadas. A câmara do
> jogo está descrita em "Câmara". Na sala de teste, dois demónios perseguem a personagem, mordem-na
> e, com o SP baixo, agarram-na; o crucifixo afasta-os, e quem morre recomeça a sala. O nível 1 já
> tem arte (chão, rochas e fundo em parallax), e o som começou pela personagem e pelo crucifixo.

Este documento tem duas partes. A primeira descreve, para toda a equipa, o que já pode ser
experimentado e as medidas que servem o desenho de níveis. A segunda, "Para quem programa",
documenta a organização técnica do projeto.

O desenho do nível 1 (as três fases, o comportamento dos cães, as medidas e a lista de verificação de
cada sala) está em `docs/nivel1_desenho.md`, e os artigos que o fundamentam em `docs/referencias/`.

## Experimentar

1. Instalar o Godot 4.7.x, versão standard (não a versão .NET).
2. No Project Manager, importar `Projeto/project.godot`. O projeto Godot encontra-se na subpasta
   `Projeto/`, e não na raiz do repositório.
3. Premir F5. O jogo abre no menu principal: New Game começa o nível 1, Settings abre as opções
   e Quit fecha o jogo. Uma cena aberta com F6 corre sozinha, sem menus nem pausa. A sala de teste,
   o blockout antigo e a sala de treino servem o desenvolvimento e ficam fora do menu: abrem-se com
   F6 (ver "Estrutura", em "Para quem programa").
4. A sala de teste (`scenes/levels/test_room/test_room.tscn`, com F6) tem um bloco elevado, com duas bordas, para experimentar os saltos a partir de
   uma borda, e uma chaminé de 120 px entre a parede esquerda e um pilar suspenso, por baixo do qual
   se entra a andar. A sala é maior do que o ecrã, e a câmara segue a personagem desde o início. Para
   a direita há uma corrida longa, uma escada de quatro degraus de 200 px, uma segunda chaminé de
   120 px junto à parede direita e, no topo desta, uma passagem que termina numa queda de 1500 px.
   Há dois demónios, um no chão da corrida longa e outro na passagem do topo (ver "Demónios").
   Durante o jogo, a tecla F3 passa pelas páginas do texto de depuração descrito em "Overlay de
   depuração" (números, luz e shaders, escondido), e a tecla F4 retira 10 SP à personagem, como um
   golpe, para experimentar a regeneração descrita em "SP".
5. O nível 1 é uma só cena, `scenes/levels/lust/level1.tscn`, com o tutorial e as fases 1, 2 e 3,
   e é ele que inicia uma partida nova. O New Game abre-o com a iluminação aprovada no protótipo,
   pela cena `scenes/levels/lust/level1_lit.tscn`, que herda o nível e lhe junta o `LightingRig`.
   O código do protótipo entra sem reescrita. O `test_level1_lit.gd` verifica que o nível arranca
   sem erros, com os mesmos nós do protótipo, que os efeitos ligados por defeito são os aprovados e
   que o recomeço e o atalho da Asmodeu mantêm a luz. As duas cenas contam como o mesmo nível nas
   estatísticas da partida (`id` = `level1`), para que passar de uma para a outra não reponha as
   mortes nem volte a abrir as ofertas por mortes. No início das fases 2 e 3, a Asmodeu
   aparece e oferece o atalho; depois de várias mortes nessas fases, volta a oferecê-lo à entrada
   da zona onde ele morre (ver "Ofertas por mortes"). Na saída, depois da fase 3 ou pelo atalho,
   ela oferece o dom e despede-se, e o jogo volta ao menu principal. O blockout antigo, com uma cena
   por fase, continua na lista Levels do Main como Level 1: Lust (old blockout), fora do menu e sem
   iniciar partida. Cada cena também corre sozinha com F6, sem gravar nada.
6. Entrar numa fase grava o jogo, o que é indicado por "Saving..." no canto do ecrã, e o menu
   principal passa a mostrar Continue e Load, descritos em "Gravação do jogo", com os três slots.
7. A sala de treino (`scenes/levels/gym/gym.tscn`, com F6) põe à prova, uma de cada vez, as mecânicas que já
   existem: movimento, paredes e chaminés, câmara, zona fixa da câmara, cães, matilha e agarrão,
   crucifixo, SP e morte. Cada estação ocupa um ecrã e tem uma placa que explica o que experimentar.
   As teclas 1 a 9 levam ao início da estação com esse número, e o 0 à décima. Quem morre recomeça
   no início da estação onde estava. Ver "Sala de treino".
Os controlos de teclado e rato escolhem-se em Settings ▸ Controls, entre três perfis. O comando é
igual em todos. No nível 1, os avisos do tutorial aparecem numa faixa em baixo, ao centro, um de
cada vez (ver "Avisos do tutorial"). Cada aviso mostra a tecla do perfil escolhido ou, se o último
aparelho usado foi o comando, o ícone do botão de um comando Xbox (A, X, RT, stick esquerdo). Muda
quando se usa o outro aparelho, quando se liga um comando e quando se desliga o último comando usado.

| Ação | WASD (predefinido) | Setas e QWEASD | Comando |
|---|---|---|---|
| Andar | A / D ou setas | setas | stick esquerdo ou D-pad |
| Saltar | Espaço | Espaço | A / Cross |
| Deslizar numa parede | no ar, A / D ou setas contra a parede | no ar, setas contra a parede | stick esquerdo ou D-pad contra a parede |
| Saltar de uma parede | no ar, Espaço encostado à parede | no ar, Espaço encostado à parede | A / Cross encostado à parede |
| Erguer o crucifixo | premir Shift no chão; fica erguido enquanto premido | premir Q no chão; fica erguido enquanto premido | premir RT / R2 no chão; fica erguido enquanto premido |
| Soltar-se de um demónio | premir Espaço repetidamente; com Hold to escape, mantê-lo premido | premir Espaço repetidamente; com Hold to escape, mantê-lo premido | premir A / Cross repetidamente; com Hold to escape, mantê-lo premido |
| Interagir | E | Ctrl | X / Square |

O terceiro perfil, Custom, começa igual ao predefinido, e cada ação pode receber outra tecla ou
botão do rato. O Esc, as teclas de depuração (F1 a F4 e F7 a F10) e a tecla Windows, que ao ser
largada abre o menu Iniciar e tira o foco ao jogo, estão reservados; o 1, o 2 e o
3, que na página dos números do texto de depuração recomeçam numa fase, não estão. As teclas W,
E, A, S e D do perfil das setas ficam livres para os upgrades.

| Ação | Teclado | Comando |
|---|---|---|
| Pausar e retomar | Esc | Start |
| Confirmar nos menus | Enter / Espaço | A / Cross |
| Voltar nos menus | Esc | B / Circle |
| Passar à página seguinte do texto de depuração (números, luz e shaders, escondido) | F3 | — |
| Retirar 10 SP à personagem (só na versão de depuração) | F4 | — |
| Recomeçar o nível na fase 1, 2 ou 3 (na página dos números do texto de depuração) | 1 / 2 / 3 | — |

## Mecânicas implementadas

A personagem mede 48 px de largura e 96 px de altura, e estas duas dimensões servem de unidade às
medidas desta secção. Todos os valores foram medidos no jogo, cuja física corre a 60 passos por
segundo, seja qual for o monitor.

### Deslocação horizontal

A personagem tem uma única velocidade, 600 px/s, sem botão de corrida, e percorre a largura de um
ecrã Full HD (1920 px) em pouco mais de 3 segundos. Atinge essa velocidade em 0,18 s, ao fim de
61 px, e, quando a tecla é libertada, desliza 40 px (pouco menos de uma largura) até parar. O
arranque demorado dá peso à personagem, e a travagem curta mantém a resposta quando o jogador quer
parar. Os valores foram revistos depois dos testes com o grupo e com os professores, em que a
personagem parecia rápida e leve demais. A corrida abrandou, o arranque ficou mais pesado e a
subida do salto mais calma, com a mesma altura e o mesmo alcance. As reduções de velocidade
resultam de elementos do jogo, como o crucifixo e o nível da preguiça.

### Queda

A velocidade de queda aumenta até um máximo de 1400 px/s, atingido após uma queda de 166 px, cerca
de uma altura e três quartos. Como a velocidade de queda é limitada, o dano de queda, quando for
implementado, será calculado a partir da altura de onde a personagem cai.

### Salto de altura variável

Com o botão premido até ao ponto mais alto, o salto atinge 240 px, duas vezes e meia a altura da
personagem. Com o botão largado logo, o salto mínimo sobe 86 px; com o botão premido durante 0,1 s,
sobe 139 px. Entre estes valores, a altura depende do tempo durante o qual o botão é mantido. A
subida demora 0,45 s e a descida 0,27 s, o que evita que o salto pareça flutuar.

O salto é definido pela altura e pelo tempo até ao ponto mais alto, a partir dos quais se calculam
a gravidade e a velocidade inicial (Pittman, 2016). Assim, o salto completo atinge exatamente a
altura definida. Libertar o botão durante a subida aumenta a gravidade, o que encurta o salto.

### Controlo aéreo

Durante o salto ou a queda, a personagem pode mudar de direção com 70 % da aceleração que tem no
chão. Acelerar, travar e inverter o sentido demoram, por isso, cerca de uma vez e meia o tempo
correspondente no chão. Ao largar a direção a meio de um salto em corrida, a personagem desliza
59 px até parar, contra 40 px no chão.

O controlo aéreo permite corrigir um salto mal calculado. O jogo avalia o jogador pelas escolhas
que faz, e mortes causadas pelos controlos levariam a aceitar atalhos por frustração. O valor de
70 % é provisório e será afinado com a câmara e nos níveis.

### Tolerâncias do salto

Um salto pedido uma fração de segundo fora de tempo é aceite, e um salto que fica poucos píxeis
abaixo de um degrau também chega a ele. O objetivo é que um salto que o jogador sente como certo
não falhe sem razão aparente, o que se confundiria com falta de resposta dos controlos; o efeito
será confirmado em playtest. As tolerâncias beneficiam também quem reage mais devagar.

- Tolerância de borda (*coyote time*): durante 0,1 s (6 passos de física) depois de sair de uma
  plataforma sem saltar, a personagem ainda pode saltar. A correr, o último salto aceite parte com a
  parte de trás do corpo 51 a 60 px para lá da borda, conforme o ponto de onde a corrida começa.
- Tolerância de aterragem (*jump buffer*): um salto pedido até 0,1 s antes de aterrar fica guardado
  e é executado no primeiro instante em contacto com o chão. A altura continua a depender do tempo
  durante o qual o botão é mantido: um toque dado antes da aterragem produz o salto mínimo.
- Ajuda nos degraus: se a personagem cai contra a parede de um degrau com os pés até 16 px abaixo
  do topo, um sexto da sua altura, a andar para ele ou só encostada, sobe o que falta e pousa.
  Como o deslize, não obriga a empurrar; mas, sem direção premida e sem velocidade própria em
  direção à parede, só atua no topo de uma subida ao longo dela, para que a personagem, ao descer
  ao longo de uma parede com um vão, não fique pousada na quina da parede de baixo. Não atua
  durante a subida do salto, que já a leva por cima, nem quando o jogador empurra para o lado
  oposto, nem nos demónios, para que os encontros com eles não mudem. Nas plataformas de sentido
  único também não atua, porque não têm um lado contra o qual a personagem bata.

Durante a tolerância de borda, a gravidade continua a atuar, para que a personagem não pareça
caminhar no ar. Por isso, o último salto aceite parte 27,5 px abaixo da borda e sobe 212,5 px acima
dela, menos 27,5 px do que um salto dado na borda. Os dois tempos passaram de 0,07 s para 0,1 s
depois dos testes com o grupo e com os professores, e podem ainda ser afinados nos níveis.

### Paredes

No ar, encostada a uma parede, a personagem pode deslizar e saltar da parede.

O deslize começa quando a personagem toca numa parede no ar, sem ser preciso empurrar, e mantém-se
sem nenhuma direção premida. Termina quando o jogador empurra para o lado oposto, salta, chega ao
chão ou a parede acaba. No lado de um demónio continua a ser preciso empurrar, para que encostar-se
a um demónio no ar não trave a queda. Na descida, a velocidade fica limitada a 350 px/s, um quarto
da velocidade máxima de queda: se a personagem cair mais depressa, trava de imediato para esse
valor; se cair mais devagar, como no topo de um salto, continua a acelerar até ele. A 350 px/s,
desce uma altura do corpo em 0,28 s. Na subida, não há travão. Dispensar a direção premida, para
entrar no deslize e para o manter, segue as Game Accessibility Guidelines (s.d.-a), que recomendam
não obrigar o jogador a manter teclas premidas. Antes, só se entrava no deslize a empurrar contra a
parede, e nos testes com o grupo e com os professores o deslize quase não aparecia.

Sem direção premida, o motor de física só deteta o contacto com a parede pela margem de segurança
da colisão (0,08 px). A partir de cerca de x = 2048 px (valor medido), os arredondamentos dos
números de 32 bits fazem esse contacto aparecer e desaparecer: no nível 1, a personagem caía a meio
de 226 das 322 paredes e, ao saltar a direito encostada a uma parede, não entrava no deslize. Por
isso, no ar e sem direção premida, a personagem é encostada 1 px por frame a uma parede do nível que
esteja a essa distância, desde que a parede esteja ao seu lado no início e no fim desse frame, para
não passar além do fim da parede nem ser levada para a quina de uma parede cujo topo passa ao cair.
O lado de um demónio fica de fora. Com esta correção, não cai a meio de nenhuma das 322 paredes, e
o custo é de até quatro testes de colisão por frame, cerca de 10 µs no pior caso.

O salto da parede é dado com a tecla de saltar sempre que a personagem toca numa parede no ar,
empurrando-a ou não. A personagem sai para o lado oposto à parede, à velocidade máxima da corrida e
com a altura de um salto completo (240 px). Como a direção do salto é sempre a de afastamento da
parede, numa chaminé basta premir a tecla de saltar, o que mantém os controlos simples (Game
Accessibility Guidelines, s.d.-b). Durante 0,2 s após o salto, a corrida não responde, e a
personagem afasta-se 120 px da parede. É este bloqueio que impede a subida de uma parede isolada:
mesmo com a melhor combinação de teclas, cada salto devolve a personagem à mesma parede 234 px mais
abaixo. Entre duas paredes próximas, numa chaminé, a subida não tem limite; na chaminé da sala de
teste, com 120 px de largura, cada salto sobe 87 px premindo apenas a tecla de saltar. A regra de
que uma parede isolada não se sobe por saltos da parede aguarda a confirmação do grupo.

Tal como na borda de uma plataforma, existe uma tolerância: durante 0,1 s depois de largar uma
parede, a tecla de saltar ainda produz o salto da parede. Os valores do deslize e do bloqueio são
provisórios e serão afinados com a câmara e nos níveis.

### Crucifixo

Enquanto o jogador recusar os upgrades, o crucifixo é a sua única defesa. Ergue-se ao premir o
Shift ou o gatilho direito do comando (RT / R2) com a personagem no chão e fica erguido enquanto o
botão estiver premido e houver carga. A carga funciona como uma bateria de 5 s: cada segundo
erguido gasta um segundo, e largar o botão guarda o resto. Com o crucifixo em baixo, a carga volta a
encher de vazia a cheia em 15 s, pelo que cada segundo gasto volta em 3 s. Um toque dado até 0,1 s
antes de aterrar ainda o ergue na aterragem, se o botão continuar premido, à semelhança da
tolerância do salto. Baixa quando o botão é largado, quando a personagem sai do chão ou quando a
carga acaba. Se a carga acabar, o crucifixo fica bloqueado durante os 15 s em que volta a encher;
um toque dado até 0,1 s antes do fim do bloqueio também conta. Depois de baixar com carga, fica
pelo menos 0,35 s em baixo, para que toques rápidos não façam a luz piscar mais de três vezes por
segundo (medido: sem este tempo, toques a cada dois frames erguiam-no 60 vezes em 2 s).

Só um toque dado durante o jogo ergue o crucifixo. Um botão que já vinha premido, do bloqueio, do
menu principal ou da pausa, não o ergue até ser largado e premido outra vez. Assim, o jogador
decide sempre o momento e, se puser o crucifixo no botão esquerdo do rato no perfil Custom, o clique
nos menus, que passa a ser o mesmo botão, nunca o ergue por engano. Durante a pausa, o tempo de uso
para.

Erguido, o crucifixo:

- abranda a personagem: a velocidade máxima desce de 600 px/s para 150 px/s (25 %);
- impede o salto. Um salto pedido com o crucifixo erguido é descartado, e não acontece quando o
  crucifixo baixa;
- afasta os demónios e as almas perdidas que estiverem a menos de 200 px; o que estiver mais longe
  não se move. As almas são empurradas para fora desse raio a 1500 px/s. Os demónios são atirados
  para longe do crucifixo, cerca de 200 px com 40 px de altura, ou só na horizontal se estiverem no
  ar, e ficam 0,3 s parados onde aterram. De muito perto, o empurrão soma-se ao arremesso enquanto
  o demónio está no raio, e ele vai parar a cerca de 300 px;
- cura 5 SP por segundo, que se somam à regeneração (ver "SP");
- acende uma luz quente cujo alcance mostra o raio do afastamento. Quando resta segundo e meio de
  carga, a luz pulsa duas vezes por segundo, cada vez mais fundo, como aviso de que o crucifixo vai
  baixar.
  A descida mais funda, para 40 % do brilho, coincide com o instante em que o crucifixo baixa. O som
  do crucifixo erguido treme com a luz e, com comando, a vibração cresce ao mesmo tempo. Duas vezes
  por segundo fica abaixo do limite de três dos critérios 2.3.1 e 2.3.2 da WCAG 2.2, para quem tem
  epilepsia fotossensível
  ([Understanding 2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html)),
  e a luz nunca se apaga.

A carga limitada obriga a escolher quando usar a única defesa. Um uso curto custa só o seu tempo,
mas esvaziar a carga custa o bloqueio inteiro: o aviso do último segundo e meio pede ao jogador que
largue o botão a tempo (ADR 0066). Ao contrário do deslize na parede, o crucifixo obriga a manter o
botão premido: o esforço de o segurar faz parte da mecânica, e cada uso está limitado à carga. Uma
opção para o erguer e baixar com toques, em vez de manter o botão premido, fica para as opções de
acessibilidade.

O jogador tem o crucifixo desde o início e perde-o, de vez, ao aceitar o primeiro upgrade: nesse
momento, o crucifixo baixa e sai do jogo. Os valores são provisórios e serão afinados em playtest.

### SP

Os SP (*Soul Points*, pontos de alma) são a vida da personagem. Começam no máximo, 100 SP, descem
com o dano e nunca saem do intervalo entre 0 e o máximo. Com 25 SP ou menos, a personagem fica com
o SP baixo, o momento a partir do qual o jogo a avisará do perigo. A 0, os SP acabam, e desde então
nem o dano nem a cura os alteram. O máximo é um valor de dados e muda sem alterar código.

Os SP recuperam sozinhos. Depois de cada golpe, a regeneração para durante 3 s, e um golpe dado
nesse intervalo recomeça a contagem. Depois, a regeneração recomeça devagar, a 0,5 SP/s, e acelera
em linha reta até 3 SP/s ao fim de 10 s, velocidade que mantém até encher. A cura do crucifixo
soma-se à regeneração e não a faz recomeçar.

A subida gradual prolonga o peso de cada golpe: logo a seguir, a personagem continua fraca durante
alguns segundos, e quem evita o dano durante mais tempo recupera mais depressa. É também nesse
momento que o crucifixo mais vale: nos 3 s de pausa cura 15 SP, e nos 3 s seguintes a regeneração
dá 2,6 SP. Comparada com uma velocidade única de 2 SP/s, depois de um golpe que deixe 20 SP, a
personagem sai do SP baixo mais tarde (7,65 s contra 5,50 s) e enche mais cedo (33,85 s contra
43,02 s), contados desde o golpe. Estes valores foram medidos com o `measure_soul_points.gd` (ver
"Testes e medidas"), que usa o componente do jogo.

As pancadas dos demónios tiram SP (ver "Pancada e agarrão"). A tecla F4 da versão de depuração
continua a retirar 10 SP, para experimentar a regeneração sem demónios. Os valores são provisórios
e afinam-se a jogar.

### Demónios

Os demónios do nível 1, o da luxúria, perseguem a personagem. Como ela não pode atacar, só pode
fugir, erguer o crucifixo ou, se for agarrada, soltar-se. Cada demónio está sempre num destes
estados:

| Estado | O que o demónio faz |
|---|---|
| Parado | Espera no seu posto, onde o nível o colocou e virado para onde o nível o virou, até reparar na personagem. Com ronda, é a pausa entre duas idas, sorteada por cada demónio entre 0,8 e 2 s. |
| Ronda | Vai e vem a passo, a 150 px/s, num troço de 480 px do seu chão, centrado no posto. Vira-se nas pontas, à beira de um desnível e contra uma parede. Fora do ecrã, fica parado. |
| Alerta | Ao reparar na personagem, vira-se para ela e fica 0,3 s parado onde está, o tempo de ladrar, antes de a perseguir. Por cima da cabeça surge um "!", com o som de alerta do cão (1,8 s); o "!" fica mais 0,5 s já na perseguição, para se conseguir ler. Quando o som de alerta acaba, se o cão ainda a perseguir, ouve-se um de dois sons de quem se fixou na presa, ao acaso. |
| Perseguir | Segue-a a cerca de 560 px/s, no chão onde está. A personagem corre a 720 px/s, pelo que fugir resulta, mas com pouca margem. |
| Aviso | Antes de cada ataque, mostra qual vem, para que o jogador tenha tempo de reagir: antes da mordida, alarga-se e baixa durante 0,1 s, sem parar de correr; antes do salto, para e encolhe durante 0,35 s. |
| Atirar-se | Salta para onde a personagem vai estar, entre 200 e 420 px, e fica 0,35 s parado onde aterra. |
| Recuar | Depois de cada ataque, afasta-se de frente para a personagem, a cerca de 400 px/s, até ficar a cerca de 130 px dela. Enquanto não pode voltar a atacar, vai e vem entre cerca de 130 e 190 px dela, a cerca de 180 px/s e sempre virado para ela, e depois corre para ela e ataca à chegada. |
| Agarrar | Segura a personagem até ela se soltar ou morrer (ver "Pancada e agarrão"). |
| Atirado | Atirado pelo crucifixo, ou pela personagem quando esta se solta, voa até aterrar. |
| Repelido | Depois de atirado pelo crucifixo, fica 0,3 s parado onde aterrou e volta a perseguir. |
| Atordoado | Depois de atirado pela personagem ao soltar-se, fica 1,2 s no chão, achatado e mais escuro, e depois recua ou volta a perseguir. |
| Fora de alcance | Com a personagem num chão ou numa parede acima ou abaixo do que os seus ataques chegam, não a segue por baixo nem por cima: para virado para ela e ladra, e depois anda para trás e para a frente num troço de 160 px à volta do sítio onde parou e, em cada ponta, volta a parar e a ladrar; contra uma parede ou na borda do seu chão, do lado dela, salta no sítio. Se ela sair do troço por cima dele, corre por baixo à velocidade da perseguição até ficar debaixo dela e anda aí. Se ela descer ao seu alcance, volta a persegui-la. Enquanto a vir, nunca desiste; se ela sair da sua vista, ladra mais 3 s para onde ela estava e depois vai procurá-la. |
| Procurar | Quando uma parede a esconde durante 0,5 s, vai a 300 px/s até onde a viu pela última vez, ou até onde o seu chão deixa, e fareja ali durante 2,5 s, virando-se para o outro lado a meio. Se a vir, fica alerta e volta a persegui-la; se não, desiste. Fora do ecrã, desiste logo. Os dois bips a descer do início da procura estão desligados (Play Beeps, no nó `DemonSounds`); o "?" sobre a cabeça está desligado desde a linha de vista (Shows Search, no nó `Mark`). |
| Voltar | Depois de desistir, volta ao posto a passo, a 200 px/s, e retoma a ronda. Se a vir à frente pelo caminho, fica alerta e volta a persegui-la. |

O demónio vê a personagem a menos de 1100 px, mais de meio ecrã, se não houver uma parede entre os
seus olhos e o meio ou a cabeça dela: um muro baixo ou uma borda que tape só uma das duas não a
esconde. Só repara nela se estiver à sua frente, ou atrás a menos de 220 px (20 % do alcance), e
por isso é possível passar-lhe pelas costas. Também só começa e continua a persegui-la enquanto ele
próprio estiver no ecrã, para que nenhum demónio venha de onde o jogador não o vê; um ataque que já
começou acaba, mesmo que o demónio saia do ecrã a meio. Continua a persegui-la para lá dos 1100 px, e
desiste quando ela se afasta mais de 1600 px ou quando ele sai do ecrã; quando uma parede a esconde,
vai procurá-la. Tem dois ataques, e só ataca a personagem praticamente à mesma altura (até 24 px
de diferença):

- **Mordida.** A menos de 100 px, morde a correr: continua a persegui-la durante o aviso e morde
  onde está.
- **Salto.** A menos de 360 px, salta às vezes, mas nunca a menos de cerca de 190 px, onde espera
  para atacar (ver abaixo): a probabilidade é de 90 % por cada segundo em que a personagem está ao
  alcance, o que torna o salto legível, pelo aviso, mas não previsível. No início do aviso, aponta
  para onde ela vai estar quando ele aterrar, se mantiver a velocidade, e não muda de pontaria:
  mudar de ritmo ou de direção durante o aviso faz o salto falhar. Nunca salta para um buraco, nem
  para uma personagem que, quando ele aterrar, já lhe terá passado.

Em grupo, cada demónio decide sozinho, mas o conjunto lê-se como uma matilha:

- os corpos dos demónios não colidem entre si, para que não tremam nem se bloqueiem. Em vez disso,
  um demónio a menos de 24 px de outro, no mesmo chão, afasta-se dele a 150 px/s, seja qual for o
  seu estado, exceto a meio de uma investida, de um salto, de uma descida ou de um arremesso, ou a
  correr na caça (ponto seguinte), e nunca para fora de uma borda; em ronda, a voltar ou fora de
  alcance, para a essa distância de outro, como numa parede. É a regra de separação dos bandos de
  Reynolds (1987). Assim, dois demónios nunca param um em cima do outro, e cada um lê-se como um
  animal à parte;
- na caça, enquanto persegue a personagem à vista dela ou avisa de um ataque, cada demónio passa
  pelos outros, e só um encostado a ela o faz parar, a 24 px dele (ADR 0053). Com ela fora de
  vista, um demónio atrás de outro fica a 24 px dele, e chegam um atrás do outro ao sítio onde a
  procuram. Só conta um demónio que também a persegue, incluindo um em alerta ou à espera fora do
  alcance: um parado, em ronda, a voltar ou a procurar não trava os outros. Dois que a procurem no
  mesmo sítio farejam à mesma distância um do outro;
- atacam à vez: de cada lado da personagem, só um demónio de cada vez avisa de um ataque ou o faz.
  Fica com a vez o primeiro que acabar a sua espera, que é sorteada, e larga-a quando morde, quando
  acaba o salto ou quando deixa de poder atacar, por exemplo se for atirado pelo crucifixo. Larga-a
  também quando não consegue chegar mais perto dela, por causa de uma borda, de uma parede ou de
  outro demónio encostado a ela, para que a vez passe a quem a pode usar. Assim, há no máximo dois
  avisos de mordida ao mesmo tempo, um de cada lado, e cada um dá tempo para fugir. A exceção é a
  personagem saltar por cima de um demónio com a vez: até à mordida seguinte de cada um, podem
  atacar dois do mesmo lado. Em 60 s, contra a personagem parada, que nesta medida não leva dano,
  cinco demónios, três de um lado e dois do outro, avisaram cada um de 56 a 65 ataques, e o maior
  intervalo sem atacar ficou entre 1,6 e 2,9 s em nove sorteios diferentes, contra até 12,7 s
  antes, porque continuam a atacar enquanto ela pisca (ADR 0055). O que avisa ou salta é desenhado
  à frente dos outros, para que nenhum o tape (ADR 0053);
- cada um persegue e recua ao seu ritmo, até 10 % acima ou abaixo dos valores, para que nunca se
  movam em uníssono. Dois a correr para o mesmo lado com os corpos sobrepostos separam-se: o que vai
  mais devagar abranda para metade até o outro passar (Pace Spread, ADR 0053);
- sempre que fica em condições de atacar, cada um espera um tempo sorteado entre 0 e 0,3 s, para
  que não ataquem todos no mesmo instante. Espera a cerca de 130 px da personagem e, depois de uma
  mordida, fica aí também o resto dos 0,3 s de recuperação; sem a vez, fica aí até ela se libertar.
  Enquanto espera, vai e vem entre cerca de 130 e 190 px dela, a cerca de 180 px/s, um terço da
  velocidade da perseguição, para que a corrida até ela se leia como o início do ataque. Troca de
  sentido numa borda, contra uma parede ou junto de outro demónio parado, e passa pelos que andam,
  para que dois encurralados nunca fiquem um em cima do outro. Entre os que se cruzam a andar para
  o mesmo lado, o da frente vai até 50 % mais depressa e o de trás até 50 % mais devagar, para que
  se separem em vez de andarem como um só. Só fica parado se estiver encurralado a menos de 130 px
  (ADR 0052). Acabada a espera, corre para ela e morde à chegada, com o aviso de
  0,1 s já em corrida, para que a pausa se sinta depois de cada ataque e nunca antes dele. O
  primeiro ataque depois de a ver não espera: o "!" e o bip do alerta já o anunciam e, com a
  personagem ao alcance, o aviso da mordida começa um passo de física (1/60 s) depois do alerta,
  sem sortear a espera (ADR 0051);
- enquanto a personagem pisca, depois de uma pancada, continuam a atacar à vez, e os ataques,
  mordidas e saltos, acertam e tiram SP. Com muitos demónios, ela perde o SP depressa e acaba
  agarrada: com cinco, três de um lado e dois do outro, fica com o SP baixo ao fim de 1,7 a 2,1 s,
  contra 5,4 a 5,9 s com um só, em nove sorteios diferentes (no sorteio do `test_demon.gd`, 2,3 s
  desde a mordida contínua nas costas, #271; os nove por medir de novo). O piscar já não a protege deles, e
  para escapar tem de fugir ou erguer o crucifixo. No segundo depois de ela se soltar de um
  agarrão, e com ela agarrada por todos os que a podem agarrar, nenhum ataca, e cada um espera no
  seu vaivém (Attacks Invulnerable Man, ADR 0055). Sem esse valor, como nos outros demónios,
  nenhum ataca enquanto ela pisca;
- mordem quem lhes está em cima. A personagem que aterra num cão, mesmo só na ponta das costas,
  leva logo a mordida dele (10 SP) e um pequeno salto no sítio, 48 px para cima (24 px até à #284,
  pouco para se sentir), e leva outra a
  cada 0,4 s enquanto lá ficar, deste cão ou de outro (Back Bite Interval, #271). Nada a empurra
  para fora: tem de sair a andar ou a saltar. Se ficar, o SP baixa e a mordida agarra-a como
  qualquer pancada, e ela cai através do cão até ao chão, onde se afunda, nunca em cima dele. Em
  cima de cinco cães seguidos, leva 8 mordidas em 3 s, sempre a 25 passos de física umas das
  outras, sem sair do sítio. O intervalo nunca desce de 0,34 s, para que os clarões das mordidas
  fiquem abaixo de três por segundo (WCAG 2.3.1). Antes, o empurrão fazia-a deslizar pelas costas
  da matilha, e cada aterragem dava uma só mordida, que a atirava 300 px para longe. Com as
  mordidas seguidas, esse arremesso levava-a de costas em costas numa matilha cerrada e, em campo
  aberto, tirava-a do meio dos cães: a matilha do `test_demon.gd` deixava-a com o SP baixo ao fim
  de 245 passos de física. Com o salto no sítio, são 138, contra 127 antes da mudança. A mordida entra em qualquer piscar, também no segundo depois de a
  personagem se soltar de um agarrão. Entre dois cães, em cima dos dois, só um morde de cada vez.
  A área que a procura cobre as costas todas: antes tinha os 48 px do demónio de pé para que foi
  feita, e nas pontas das costas do cão ninguém era mordido. Só morde quem está em cima do cão:
  encostar-se a ele, saltar ao lado dele ou atravessá-lo, mesmo a saltar para fora dele, não
  (Bites Who Lands On It, ADR 0056). Um demónio pode ainda atirar a personagem ao longo do chão
  (Back Bite Knockback Distance), e junto a uma parede que não lhe deixa espaço ao lado atira-a
  para o lado aberto. Sem a mordida, como nos outros demónios, a personagem é só empurrada para
  fora de cima dele (ADR 0022).

Todos os saltos de um demónio caem com a mesma gravidade e com o mesmo ângulo, como um salto dado
com menos força: um salto mais curto é mais baixo e mais rápido. O de 420 px sobe 32 px e dura
cerca de 0,31 s, pela conta; o de 200 px, medido pelo `measure_demon.gd` contra a personagem
parada, sobe 15,22 px (15,2 pela conta) e está de novo no chão 0,22 s depois de partir (ver "Salto
calculado a partir do desenho"). Os valores são provisórios e afinam-se a jogar.

É o desenho do nível que limita os demónios. Por omissão, um demónio não sobe, não salta para cima
e para à beira de um desnível (ver a seguir a opção que o deixa subir e descer). Como nenhum salto passa dos 32 px de altura, um degrau de 48 px, uma largura da
personagem, trava-o, e uma plataforma dessa altura protege-a dos ataques. Só é um refúgio se tiver
uma saída para fora da vista dos demónios, porque um demónio que a vê nunca desiste (ver "Nunca
desiste enquanto a vê", em "Para quem programa"). Um demónio que veja a
personagem num sítio desses para onde está, virado para ela, em vez de a acompanhar por baixo de um
lado para o outro, e o jogador lê que ali não lhe chega. O mesmo vale ao contrário: um demónio numa
plataforma alta, de onde não desce, não corre até à borda para a acompanhar lá de cima. Um salto da personagem no chão do demónio
não conta, porque ela só pode voltar a descer: a perseguição continua. Quem desenha um nível sabe
assim até onde cada demónio chega, sem limites invisíveis. A exceção é o crucifixo, que pode
atirar um demónio de uma borda abaixo: o demónio cai, fica no chão onde aterra e, se vir a
personagem, persegue-a a partir daí. Quando desiste, tenta voltar ao posto, e fica onde a borda ou
uma parede o param, fazendo aí a ronda; nunca fica a tentar subir. O posto não muda: de cada vez que
desiste, volta a tentar chegar-lhe. É uma mecânica: o jogador pode gastar o crucifixo para tirar
um demónio do caminho, e os níveis podem oferecer-lhe bordas e buracos para onde o atirar.

Uma opção, desligada no demónio da luxúria, deixa um demónio subir e descer atrás da personagem,
com alturas a que só ela chega (o salto dela sobe 240 px). Liga-se com dois valores do ficheiro de
dados: Jump Height, o degrau mais alto que o demónio sobe, e Max Drop, a queda mais funda que
desce; a 0, o demónio comporta-se como acima. Ligá-la num nível contraria a regra "o chão é dos
cães" do nível 1 e é uma decisão do grupo. Na sala de testes e na estação 10 da sala de treino, os
demónios usam-na com 96 px e 240 px:

- **Subir.** Com a personagem acima do seu alcance e um degrau no caminho, o demónio salta-o a
  correr, com a gravidade do seu salto de ataque, e passa a quina com 6 px de folga. Sem aviso: o
  aviso diria ao jogador que vem um ataque. Um degrau mais alto do que Jump Height, uma plataforma
  por cima dele ou a borda do seu chão deixam-no fora de alcance, como antes.
- **Descer.** Com a personagem abaixo do seu alcance, desce a borda aos saltos, com o mesmo salto.
  Antes de descolar, joga o arco passo a passo e só salta se aterrar num chão até Max Drop mais
  abaixo; uma parede, um teto ou o vazio deixam-no fora de alcance. À velocidade do cão mais rápido
  da matilha (561 px/s), o corpo aterra todo até cerca de 230 px depois da quina numa queda de 96 px,
  e até cerca de 314 px numa de 240 px; lá em baixo, esse chão tem de estar livre.
- **Voltar.** O demónio guarda o caminho por onde saiu do seu chão, até 8 passos, e no regresso
  refá-lo do último para o primeiro. Um passo que não consegue desfazer, como uma queda mais funda
  do que o seu salto, deixa-o nesse chão (ver "Posto e regresso"). Ao procurar a personagem, sobe e
  desce até ao chão onde a viu pela última vez.

Ao descolar, o retângulo provisório estica (0,8 × 1,25) e, ao aterrar, encolhe (1,25 × 0,75),
voltando ao tamanho em 0,2 s. Ao descolar, e também ao atirar-se à personagem, ouve-se um salto
provisório; os bips de descolar e de aterrar estão desligados.

Os valores são os do demónio da luxúria, num ficheiro de dados (`scenes/characters/demon/lust_demon_stats.tres`);
mudam sem alterar código e são provisórios. O aviso é, por agora, um retângulo que muda de forma e
de cor, com uma forma para cada ataque, à espera da arte e do som; a mordida precisa de uma animação
e de um som próprios. O demónio do tutorial, que fala e não persegue, terá uma cena própria
(ver "Demónio: estados, dados e famílias de personagens").

### Pancada e agarrão

Um demónio nunca mata com uma pancada: a morte vem sempre de um agarrão, a que o jogador pode
resistir. Com o SP acima do baixo, a mordida tira 10 SP e o salto 20, e a pancada atira a
personagem para trás e para cima (150 px e 40 px de altura na mordida, 250 px e 70 px no salto), sem
controlo até aterrar. A seguir, a personagem fica 1 s invulnerável, a piscar, mas os ataques dos
demónios do nível 1 acertam na mesma (ADR 0055).

Com o SP baixo (25 SP ou menos), ou quando a pancada a deixaria a 0, o demónio agarra-a em vez de
lhe tirar SP. Agarrada, a personagem para logo, não corre nem salta, e o crucifixo baixa; se for
agarrada no ar, mesmo encostada a uma parede, cai a direito até ao chão. Solta-se premindo o salto
repetidamente: 8 vezes, com um demónio. A animação de fuga corre durante todo o agarrão, e cada
toque troca a mão que a personagem tem levantada, para que cada toque se veja. Um segundo demónio
pode juntar-se a meio, e pede mais 6. Com dois, o agarrão fica cheio: nenhuma pancada entra, e os
outros demónios esperam a cerca de 130 px. Se o jogador parar de premir, o progresso desce: ao fim de 0,25 s sem premir, perde metade
da barra por segundo, pelo que quem prime 4 vezes por segundo não perde nada. Se não se soltar em
3 s, a personagem morre, aparece "Another fall.", o ecrã escurece e o nível recomeça 0,7 s depois. Se morrer por outra
causa enquanto está agarrada, como nos picos letais, o agarrão acaba da mesma forma: os toques
deixam de contar e aparece "Another fall." (os demónios contam as mortes como quedas, como nas falas
da Asmodeu).

Durante o agarrão, a personagem e os demónios que a agarram afundam-se no chão, até 96 px, ao ritmo
do tempo que passa: o jogador vê quanto tempo lhe resta sem olhar para um número. O afundar é só
desenho, porque os corpos não se enterram, e por isso funciona em qualquer chão, mesmo numa
plataforma fina. Por agora não tem som.

Ao soltar-se, a personagem atira os demónios que a agarravam para longe (200 px, com 40 px de
altura), e cada um fica 1,2 s atordoado no chão. É a janela para fugir, e vê-se no ecrã. A
personagem fica ainda 1 s invulnerável a todas as pancadas, também às dos demónios do nível 1,
para não ser agarrada de novo logo a seguir.

A personagem e os demónios não se atravessam: param encostados, também a meio de um salto. A
personagem nunca fica de pé em cima de um demónio: é empurrada para o lado a 600 px/s, sem correr
nem saltar até pisar outra coisa. Assim, a cabeça de um demónio, onde a mordida não chega, nunca é
um sítio seguro. O mesmo vale ao contrário: um demónio nunca fica de pé em cima da personagem, e é
empurrado para o lado a 600 px/s. Se os dois ficarem presos, porque o empurrão bate em paredes dos
dois lados, como num buraco da largura de um corpo, atravessam-se ao fim de 0,1 s até se
separarem; enquanto se sobrepõem, o demónio não ataca.

Os valores estão em `scenes/characters/player/grab_stats.tres` (o agarrão), no ficheiro de dados dos demónios (o dano
e os arremessos) e na cena da personagem (a invulnerabilidade), e são provisórios.

Para quem não consegue premir depressa, a opção Hold to escape (ecrã Options, por baixo de Constant
vibration) troca os toques por manter o salto premido: 1,2 s com um demónio, mais 0,9 s com o
segundo, o que cabe nos 3 s do agarrão. Só conta a partir de um toque dado já durante o agarrão,
para que um salto que vinha premido de antes não solte a personagem sozinho, e o texto passa de
"Break free!" a "Hold to break free". O texto não escreve o nome da ação: ao lado aparece a tecla do
salto no aparelho usado por último, como na faixa do tutorial (`PromptGlyph`, #284,
`test_grab_prompt_glyph.gd`). O texto desenha-se por cima da rocha (z 10), embora a
personagem fique atrás dela, para se ver sempre (#284, `test_grab_prompt_over_rock.gd`). Largar o salto esvazia a barra como parar de premir: ao fim de 0,25 s,
metade da barra por segundo. Com a opção ligada, os toques deixam de contar; aceitar as duas formas
faria da opção um atalho para todos, porque cada toque somaria também o tempo premido. A opção vem
desligada, porque os toques são o agarrão tal como foi desenhado, e guarda-se com as outras. O
agarrão lê-a em cada frame: ligada ou desligada na pausa a meio de um agarrão, vale assim que o jogo
continua, e o texto muda com ela, como acontece com as opções do tremor e da vibração. Mudar de modo
a meio não perde o progresso, porque os toques e o tempo premido enchem a mesma barra.

### Portões, picos letais e plataformas que desabam

Cinco elementos para qualquer nível, cada um numa cena própria, que se coloca na cena do nível e se
ajusta no Inspector. Por agora são formas provisórias, até chegar a arte, exceto os picos, que já
são silvas.

| Elemento | Cena | Comportamento | Medida |
|---|---|---|---|
| Portão | `scenes/objects/gates/gate.tscn` | barra uma passagem à personagem, aos demónios e à visão destes; desbloqueado, sobe a sua própria altura, por trás da rocha; com Slide Way em Left ou Right, é um alçapão e desliza para esse lado a sua própria largura; pode também ser posto aberto de imediato e trancado outra vez, deslizando de volta ao seu lugar, para uma cena de câmara o mostrar a fechar; desenha-se como uma porta de blocos de pedra num caixilho, com um poste atrás e um pilar à frente (`GateArt`, #284): ao abrir, a arte fica no seu lugar e a porta tomba durante o deslize, enquanto o corpo sobe por trás da rocha, e desaparece quando o portão dá a passagem por livre; ao fechar, volta a erguer-se; num alçapão, a porta aparece deitada, com o topo onde a personagem pisa, e desliza com ele, sem caixilho; o poste de trás desenha-se atrás da personagem e dos cães, como o portão, e a porta e o pilar da frente à frente deles, para a personagem passar entre o poste e o pilar (no jogo, passam para o nó `GateFronts` do próprio nível, depois dos cães e antes da rocha, e seguem a arte por um `RemoteTransform2D`; saem com o portão quando ele é libertado; `test_gate_fronts.gd`); tudo fica atrás da rocha | desliza em 0,8 s (48 passos de física), para abrir e para fechar; a porta tomba em 10 imagens e volta em 9, repartidas por esses 0,8 s; tem a largura do portão (96 px com 2 tiles), à mesma escala nos dois eixos, e o que passa do topo fica escondido pela rocha |
| Desbloqueador | `scenes/objects/gates/gate_unlocker.tscn` | ativa-se uma vez, com a ação de interagir (E, ou X no comando) ao pé dele, e abre os portões da lista Gates; enquanto a personagem está perto e ele ainda não foi usado, mostra por cima a tecla e a palavra "Unlock", como a Velvet mostra "Talk", desenhadas por cima da rocha (Z Index 10, como o aviso do agarrão), porque numa sala baixa ficam dentro do teto; o crucifixo já não o abre; com uma cena de câmara (Cutscene), a câmara vai primeiro ao portão e este só abre quando ela lá chega; desenha-se como uma estátua de demónio, apagada até ser usada e com uma chama acesa depois (#284), para que usado e por usar se distingam pela forma e pela luz, e não só pela cor; acesa, ilumina a sala à volta como um fogo mais fraco, com a cor dos fogos e metade da energia e do alcance (luz do `LightingRig`, só no modo de luz do nível) | área de uso de 400 × 192 px, 200 px para cada lado, o alcance que tinha o crucifixo; a chama tem 9 imagens de 0,11 s (Flame Frame Time); a estátua, a 0,6 da escala do desenho, tem cerca de 215 px de altura com a chama |
| Anel de proximidade | `scenes/objects/gates/proximity_unlocker.tscn` | ativa-se uma vez, na primeira vez que a personagem entra no círculo, sem crucifixo, e abre os portões da lista Gates | alcance (Reach) de 288 px por omissão |
| Picos letais | `scenes/objects/traps/lethal_spikes.tscn` | um toque mata a personagem de imediato, com qualquer valor de SP, e as silvas puxam-na para dentro (por baixo da tabela). Com Catches ligado (desligado por defeito, ADR 0067), prendem-na em vez disso: corre a 10 % da velocidade, não salta, afunda e perde 150 SP por segundo, e morre se o SP acabar lá dentro (valores no nó `Snag` do `player.tscn`, `test_snag.gd`); os demónios passam por cima sem efeito; desenham-se como silvas, um arbusto e meio por tile, em média (Brambles Per Tile; com um só, a sebe ficava rala), para formarem uma sebe contínua, com a altura e o espelho escolhidos ao acaso a partir da posição da faixa, que fica sempre igual; sem arte (Art), voltam aos dentes; uma faixa no chão nasce entre as pedras da rocha, e uma virada para uma parede ou um teto desenha-se por cima da rocha (Turned Z Index, 2), para as silvas se verem (#284, `test_drawn_over_the_rock.gd`) | parte que mata com 24 px de altura e 4 px de folga em cada ponta, para um salto que passe à vista passar mesmo; cada arbusto com 40 px de altura, mais ou menos 10 %, que cobre a parte que mata de ponta a ponta (`test_lethal_spikes_art.gd`) |
| Plataforma que desaba | `scenes/objects/platforms/collapsing_platform.tscn` | usa o mesmo tile das plataformas de sentido único; pousar nela faz com que estale e desapareça; saltar através dela, de baixo, não a ativa; volta ao fim de Come Back Time, com 0 fica desaparecida até o nível recomeçar; desenha-se como uma laje fina, mais fina do que a das plataformas que aguentam (`CollapsingPlatformArt`, #284), que racha enquanto aguenta e se parte quando desaparece; os tiles continuam a piscar por baixo, invisíveis no nível iluminado | desaparece em 0,6 s (36 passos) e volta ao fim de 3 s; racha em 5 imagens repartidas pelos 0,6 s, parte-se em 2 de 0,11 s e esbate-se em 0,2 s; volta inteira em 0,25 s; acima de 4 tiles leva uma laje por cada 4, a segunda espelhada |

A largura e a altura destes elementos definem-se em tiles, no Inspector. A morte imediata é o método
`die()` da personagem, que a imobiliza e fecha a sua caixa de dano, enquanto o nível recomeça.

Quando as silvas a matam, o jogo congela 0,1 s, a única paragem do jogo, com a personagem desenhada
a branco. Durante o congelamento, o jogo corre a 2 % da velocidade e não a zero: com o tempo parado,
cada script receberia um intervalo de 0 s entre frames, e a câmara e os cães dividem por ele
(`test_bramble_death.gd` verifica que nunca chega a 0). Depois, as silvas puxam-na para dentro em 0,6 s, cada vez mais depressa. Num chão de
silvas, afunda-se cortada à altura do chão, como quando os cães a agarram, e o que desce fica atrás
da rocha: ainda se vê quase inteira 0,2 s depois do congelamento e desaparece aos 0,5 s, quando o
ecrã já escurece. Numa parede ou num teto, é puxada 10 px para dentro da sebe. A curva acelera para
que o corpo se veja até ao escuro: com o puxão mais forte no início, desaparecia em 0,3 s e ficava
meio segundo de silvas vazias. As silvas a menos de três tiles agitam-se com força desde o primeiro
instante, 16 px no topo, e a agitação cai para cerca de um terço em 0,45 s; ao mesmo tempo,
inclinam-se para o sítio da morte. Fora da morte, cada arbusto balança devagar, com fase própria
(2 px, uma oscilação em 2,5 a 4 s), e estremece quando a personagem avança para ele a menos de um
tile. Os desenhos mudam 20 vezes por segundo, como os outros efeitos. Os valores estão em
`scenes/characters/player/bramble_death_stats.tres` (a morte) e em
`scenes/objects/traps/bramble_motion_stats.tres` (o movimento das silvas). O movimento de todas as
silvas do nível 1 (72 faixas, 465 arbustos) custa 71,9 µs em cada frame dos efeitos, cerca de 24 µs
por frame a 60 fps; o tempo de frame com as silvas paradas e a mexer fica dentro do ruído (4,1 a
4,3 ms, `tests/measures/measure_brambles.gd`). Ficam no código, desligadas por omissão, duas versões
experimentadas e recusadas: a personagem cortada pelos espinhos (Cut Apart) e ramos que a enrolam
(Vines). Testes: `test_bramble_motion.gd`, `test_bramble_death.gd`, `test_bramble_pull.gd` e
`test_bramble_cut.gd`.

O cão
grande (`scenes/characters/demon/big_demon.tscn`), na fase 2 do nível 1, é o demónio normal 1,25 vezes maior: o corpo
(140 × 70 px), a caixa de ataque, a arte e as verificações aos pés. No ecrã, distingue-se do cão
normal pelo tamanho e pela arte, num tom verde pálido próprio (Self Modulate do `Sprite`, 0,8; 1;
0,85), para que a diferença se leia de relance e não dependa só do tamanho; os avisos de ataque
clareiam-na na mesma proporção que no cão normal. O tom tem 95 % do brilho do cão normal e fica longe
do amarelo dos avisos, para que o cão grande parado não pareça um cão a avisar. Antes, a arte estava
escurecida a 60 % do brilho, e na gruta, onde o mais escuro se desenha mais longe, o cão grande
parecia estar atrás dos outros, entalado entre eles (#271). Tem valores próprios (`scenes/characters/demon/big_demon_stats.tres`), iguais aos do cão normal
exceto no dano: 25 SP no salto e 12,5 SP na mordida, contra 20 e 10. A fase 2 fica assim mais
exigente: com 100 SP e sem tempo para regenerar, o quarto salto do cão grande já agarra a personagem,
em vez do quinto. O `test_big_dog.gd` falha se os valores dos dois cães diferirem em algo além do
dano, para que nenhuma afinação do cão normal fique por passar para o grande. Falha também se a arte
do cão grande, parado, a avisar ou atordoado, perder o tom próprio (saturação abaixo de 0,15), se o
tom ficar a menos de 60° do matiz de um aviso ou se descer abaixo de 90 % do brilho do cão normal.
O maior cão
(`scenes/characters/demon/biggest_demon.tscn`), no fim da fase 3 do nível 1, é o demónio normal 1,5
vezes maior (corpo de 168 × 84 px, caixa de ataque, arte e verificações aos pés), um pouco maior do
que o cão grande, com um anel de proximidade de 736 px de alcance à volta do meio do corpo: chegar
perto dele abre os portões da sua lista Opens. É o cão que persegue a personagem até ao fim (#271):
depois de a notar no ecrã, nunca desiste dela (Never Gives Up), esteja ela escondida, fora do ecrã ou
longe; só o ataque depende de a ver. Não vai direito a ela: segue-lhe o rasto (Follows Trail), como
um cão pelo cheiro. A classe pura `DemonTrail` guarda um passo cada vez que a personagem aterra num
chão a outra altura, com o sítio onde ela deixou o chão anterior e o sítio onde aterrou, até 32
passos. O cão percorre-os pela ordem: sobe com um salto calculado para aterrar onde ela aterrou, que
o motor de física simula contra o nível antes de o cão saltar, e desce onde ela desceu. Na descida, a
simulação ignora a personagem, para que o corpo dela no caminho não anule a descida (o cão é empurrado
para o lado dela). Na subida conta com ela: um salto que toque nela falha. Se ela estiver parada onde
o cão aterraria, ele aponta para o lado dela, do seu próprio lado, e só salta se houver chão debaixo
do meio do corpo nesse sítio. Numa plataforma larga, sobe e aterra ao lado dela. Numa plataforma mais
estreita do que os dois, venha o cão de baixo ou de lado, não salta e ladra-lhe de baixo, como num
refúgio, até ela sair dali. O mesmo acontece num chão largo, se ela estiver parada perto da beira do
lado do cão, sem espaço para o corpo dele ao lado: para chegar ao outro lado, o cão teria de lhe
saltar por cima. Numa plataforma de sentido único, acaba por passar por baixo dela para o outro lado
e sobe por aí. As costas de um cão não contam como chão do rasto. Se o cão cair ou for atirado para um chão por onde já passou, retoma o
rasto a partir daí. Enquanto a vê ao seu alcance, persegue-a como os outros cães e esquece o rasto.
Um passo que não consegue dar (mais alto do que o salto, um fosso largo demais para o saltar, ou uma
descida sem chão onde aterrar) faz-lhe largar o rasto durante o Trail Retry Time (1,5 s): persegue-a
como os outros cães, e ladra quando ela está fora do seu alcance, e depois tenta outra vez. Se ela
aterrar noutro chão antes disso, o cão tenta logo, sem esperar o resto do tempo. A caminho
de um salto, nunca sai do seu chão para um fosso mais largo do que o corpo. O salto dele vai até à
altura do salto dela (Jump Height de 240 px;
medido: sobe um degrau de 224 px e não um de 280 px, e sobe para uma plataforma de sentido único de
144 px, mais estreita do que o corpo), e o Max Drop de 1536 px cobre a descida mais funda do caminho
de fuga, a chaminé atrás do portão 3 (1488 px), com um tile de folga (medido: desce 700 px de uma
beira em campo aberto). Com Drops Down Shafts, uma descida que bate numa parede escorrega por ela
abaixo, como o corpo faz, e o cão desce poços mais estreitos do que o seu salto (medido: um poço de
192 px de largura e 1488 px de fundo); só o maior cão o tem. O rasto tem três limites conhecidos:
um salto da personagem por cima de um buraco mais largo do que o cão, sem mudar de altura, não fica
no rasto; um salto dela de parede em parede não se repete; e dois chãos à mesma altura contam como
um só. Custo medido (`tests/measures/measure_dog_trail.gd`, três execuções alternadas de 300
frames): o frame inteiro leva em média 213 a 214 µs com o rasto ligado e 200 a 215 µs sem ele, uma
diferença dentro do ruído da medição. A fuga pensada é esse caminho: a
personagem encontra-o no salão do fundo, volta para oeste, sobe a coluna até ao portão 3, que o anel
dele abriu, segue o corredor e cai pela chaminé no salão, com ele atrás. A saída fica fechada pelo
portão 4, na passagem por baixo do pilar entre o posto do cão e o F, até a personagem usar o mecanismo
a meio do corredor, entre o poço e a chaminé; saltar por cima do cão no salão não leva a lado nenhum.
Para que ele a possa seguir, o fundo oeste do salão sobe em quatro degraus de 192, 192, 144 e 96 px
(antes, dois de 384 e 240 px), as plataformas da coluna deixaram de cair e a chaminé passou de 3 para
4 tiles de largura (192 px, para um corpo de 168 px). O `test_level1_escape_loop.gd` verifica estas
medidas na cena; o `test_dog_trail.gd` verifica que o cão faz o caminho todo atrás dela, no nível 1,
até voltar ao salão pela chaminé; o `test_dog_shafts.gd`, que desce o degrau, o poço e a chaminé do
corredor; e o `test_level1_exit_gate.gd`, que não há outra passagem para o F. Antes era oito vezes
maior (896 × 448 px) e tapava o salão. Os
valores dos cães medem a distância à personagem a partir do meio do
corpo, o que num corpo maior deixa os ataques curtos: a 1,5 vezes, encosta-se a ela a 108 px, e a
mordida do cão normal só chega a 100. Tem por isso valores próprios
(`scenes/characters/demon/biggest_demon_stats.tres`), os do cão normal com cada distância à
personagem medida a partir da cara, 28 px mais longe do meio, arredondados à dezena: vê-a até 1130 px, perde-a a 1630 px,
morde a 130 px, salta a 390 px e recua para 160 px; a variação da matilha (Pack Variation) desce para
0,08, para que o recuo varie os mesmos 13 px que no cão normal. A área da mordida nas costas tem as
medidas dele (168 × 72 px). O `test_biggest_dog.gd` falha se os valores dele diferirem dos do cão
normal em algo além destas distâncias, da perseguição sem fim, do salto e da descida, ou se estas
distâncias deixarem de ser as do cão medidas a partir da cara, a visão incluída; falha também se não
notar, morder ou perseguir a personagem como descrito, se as costas dele não morderem ou se a atacar
escondida atrás de uma parede.

Desde a #284, a pedido do grupo depois do playtest, em que se lia como fraco, o cão maior é a ameaça
final da perseguição, de que a personagem só pode fugir:

- As mordidas dele matam de um golpe, com qualquer valor de SP (Kills, no ataque). É a única
  exceção à regra de que um demónio agarra em vez de matar (ADR 0021). Avisa 0,35 s antes, em vez
  de 0,1 s, para que o golpe se possa ler.
- Persegue a 550 px/s em vez de 510. Com a variação da matilha fica entre 506 e 594 px/s, sempre
  abaixo dos 600 px/s da personagem, para que a fuga continue possível.
- O crucifixo não o afeta (Ignores Crucifix): o Repellable dele não fica em nenhuma camada, e por
  isso o crucifixo nem o empurra nem conta um toque nele.
- Com a personagem noutra plataforma, até à altura do salto dele (240 px) e a menos de 390 px, salta
  para ela (Leaps To Other Floors, no ataque de salto), num arco do seu salto que passa pelos pés
  dela. Mira onde ela está quando começa o aviso, e quem sair dali escapa: nos testes, a
  personagem parada que começa a correr quando o aviso começa, ou que dá 220 px pela plataforma,
  já não está onde ele aterra. Se nenhum arco chegar a ela quando o aviso começa, o aviso acaba
  sem ataque. Prefere o arco mais baixo que não passe da velocidade de perseguição, depois o mais
  alto; só se nenhum chegar vai mais depressa, até à velocidade do seu salto em frente. Antes
  ficava a ladrar por baixo dela (o refúgio da #271).
- A mordida nas costas continua a não matar, para que saltar-lhe por cima continue a ser um caminho
  (ADR 0073).

O `test_biggest_dog_threat.gd` joga estes casos: a mordida mata (a de um cão normal não), o
crucifixo não lhe chega, salta para a personagem numa plataforma 192 px acima, e falha quem saiu
durante o aviso.

### Linha de vista

Os cães (o demónio normal, o grande e o maior) e os picos letais só se veem quando a personagem os
vê. A Asmodeu e a Velvet veem-se sempre. A partir dos olhos da personagem, a 84 px dos pés, o jogo
verifica se algum corpo na camada world (o chão, as paredes e o que mais lá estiver) se interpõe
entre ela e três filas de pontos de cada um destes elementos, do topo à base; nos picos, a fila de
cima fica à altura dos dentes desenhados. Se a personagem vir pelo menos metade dos pontos, o
elemento desenha-se por inteiro; se vir menos, desenha-se em parte, na proporção dessa metade (um
ponto visto em seis dá um terço da opacidade), para que uma aresta de rocha o esbata em vez de o
cortar. Os picos vistos em parte desenham-se por inteiro, porque ficam na memória. O que está a
menos de 96 px dos olhos vê-se através de tudo. As plataformas de sentido único não tapam a vista,
tal como na visão dos cães, nem o corpo de uma personagem que esteja na camada world, como o da
Velvet. A personagem não vê para lá do ecrã, com 192 px de margem. As plataformas, as paredes e o
fundo veem-se sempre.

| Elemento | Aparece | Desaparece |
|---|---|---|
| Cão | quando a personagem o vê, ou quando ele vê a personagem | 0,3 s depois de deixar de ser visto, ao longo de 0,4 s |
| Picos letais | da primeira vez que a personagem os vê | só quando o nível recomeça |

Um cão que vê a personagem está sempre visível, e fica desenhado por inteiro no instante em que
começa o aviso de um ataque, pelo que nenhum ataca sem ser visto. Aparecer demora 0,15 s, e um
elemento na borda da vista mantém-se desenhado durante 0,3 s, para que nada pisque mais de três
vezes por segundo (critério 2.3.1 da WCAG 2.2); o Inspector não deixa baixar este tempo de 0,3 s. Os
sons dos cães continuam a ouvir-se fora da vista. Quando a personagem morre, o nível recomeça e os
picos voltam a ficar escondidos até serem vistos, de acordo com a regra de que a morte repõe a fase
tal como estava na última gravação. A opção de acessibilidade Show hidden dangers, desligada por
omissão, mostra tudo. Os valores estão no nó `SightReveal` de `demon.tscn` e de `lethal_spikes.tscn`
(Fade In Time, Fade Out Time, Linger Time e Spot Rise) e no nó `Eyes` da personagem (Screen
Margin), e afinam-se no Inspector, também durante o jogo, no separador Remote.

## Medidas para o desenho de níveis

| Medida | Valor | Em dimensões da personagem |
|---|---|---|
| Altura do salto completo (altura máxima dos pés) | 240 px | 2,5 alturas |
| Altura do salto com o botão premido durante 0,1 s | 139 px | 1,4 alturas |
| Altura do salto mínimo, com o botão largado logo | 86 px | menos de 1 altura |
| Vão mais largo que um salto em corrida atravessa, de borda a borda | 488 a 497 px | 10 larguras |
| Vão mais largo, com o salto dado no último instante da tolerância de borda | 538 a 547 px | 11 larguras |
| Altura máxima, acima da borda, do salto dado no último instante da tolerância de borda | 212,5 px | 2,2 alturas |
| Tempo no ar num salto completo | 0,72 s | |
| Distância de travagem no chão | 40 px | 0,8 larguras |
| Distância de travagem no ar | 59 px | 1,2 larguras |
| Queda até à velocidade máxima | 166 px | 1,7 alturas |
| Altura máxima de um salto completo junto a uma parede seguido de um salto da parede | 477 px | 5 alturas |
| Distância à parede no ponto mais alto desse salto, com a direção para fora | 270 px | 5,6 larguras |
| Distância de um salto da parede, com a direção para fora, até voltar à altura de partida | 440 px | 9,2 larguras |
| Chaminé mais larga que se sobe premindo apenas a tecla de saltar ao tocar na parede | 211 px | 4,4 larguras |
| Chaminé mais larga que se sobe premindo a tecla 0,1 s depois de tocar na parede | 200 px | 4,2 larguras |
| Chaminé mais larga que se sobe com a melhor combinação de teclas | 478 px | 10 larguras |
| Subida por salto numa chaminé de 120 px, premindo apenas a tecla de saltar | 87 px | quase 1 altura |
| Descida por salto numa parede isolada, com a melhor combinação de teclas | 234 px | 2,4 alturas |
| Tempo de deslize por cada altura do corpo | 0,28 s | |
| Subida máxima da ajuda nos degraus | 16 px | um sexto de altura |

- Os vãos máximos variam alguns píxeis com o ponto de onde a corrida começa, porque a física avança
  em passos de 1/60 s; foram medidos a partir de 10 pontos de partida, e a tabela dá o menor e o
  maior valor. Já contam com a ajuda nos degraus, que apanha os saltos que chegam à borda oposta um
  pouco abaixo do topo.
- Longe de paredes, uma plataforma a 240 px só é alcançável com um salto completo. A ajuda nos
  degraus estende esse alcance em até 16 px, se o salto acabar contra a parede da plataforma. Os
  níveis devem deixar margem.
- A personagem ainda consegue saltar com parte do corpo fora da plataforma, e os vãos medidos já
  contam com isso.
- A tolerância de borda é uma margem para o jogador, e não alcance para o nível. Um vão que deva ser
  sempre transponível não deve passar de 440 px: o menor vão máximo medido (488 px) menos uma
  largura do corpo, para que o salto ainda passe se for dado até uma largura antes da borda. Um vão
  que deva ser intransponível deve medir pelo menos 595 px: o maior vão medido com a tolerância
  (547 px) mais uma largura do corpo.
- Se uma opção de acessibilidade vier a alargar a tolerância de borda, o limite dos vãos
  intransponíveis terá de subir, e o vão volta a ser medido com o novo tempo.
- As medidas das paredes não dependem do ponto de partida, porque cada salto da parede define as
  duas velocidades da personagem.
- Uma parede que a personagem consiga tocar durante um salto aumenta a altura alcançável. Uma
  plataforma que deva ser sempre alcançável com a ajuda de uma parede não deve ficar a mais de
  381 px acima do ponto de partida: a altura medida (477 px) menos uma altura do corpo. Uma
  plataforma que deva ser inalcançável, havendo uma parede ao alcance de um salto, deve ficar a pelo
  menos 573 px: a altura medida mais uma altura do corpo.
- A altura medida junto a uma parede supõe que o jogador larga a tecla de saltar durante um só passo
  de física (1/60 s) antes de a premir para o salto da parede. Nesse passo, a personagem ainda sobe
  sem o botão premido e fica sujeita à gravidade do salto curto, razão pela qual a altura não chega
  ao dobro de um salto completo (480 px). Largar a tecla durante mais passos baixa a altura máxima.
  Com o salto da parede dado até 0,1 s fora do melhor momento, e a tecla largada durante um só
  passo, a personagem chega aos 461 px. Os dois valores medidos ficam entre os dois limites
  anteriores (381 e 573 px).
- Uma chaminé que deva ser sempre subida não deve passar de 163 px de largura: a maior largura
  medida premindo apenas a tecla de saltar (211 px) menos uma largura do corpo. Premir a tecla
  0,1 s depois de tocar na parede reduz essa largura para 200 px, valor que a margem cobre. Uma
  chaminé que não deva ser subida deve medir pelo menos 526 px: a maior largura medida com a melhor
  combinação de teclas (478 px) mais uma largura do corpo. Entre 163 e 526 px, a subida depende da
  perícia do jogador, pelo que estas larguras devem ficar fora do caminho obrigatório, reservadas a
  desafios opcionais.
- Uma parede isolada não se sobe por saltos da parede, qualquer que seja a sua altura: cada
  salto devolve a personagem à parede 234 px mais abaixo. O topo dessa parede alcança-se como o de
  uma plataforma, com um salto normal; uma parede de 200 px, por exemplo, sobe-se assim.
- Os valores podem ainda ser afinados nos níveis. Após cada afinação, as medidas voltam a ser
  obtidas com o `measure_movement.gd` (ver "Testes e medidas").
- Os níveis podem vir a ser construídos com tiles ou com cenário pintado. Quando o tamanho do tile
  for definido, estas medidas serão convertidas em tiles.

## Câmara

A câmara segue a personagem com técnicas descritas por Keren (2015), escolhidas para as situações
deste jogo: a corrida, as chaminés, as subidas e as quedas. As medidas foram obtidas nos testes, a
60 passos de física por segundo, num ecrã de 1920×1080.

Para comparar em playtest, a câmara tem também uma forma de zoom fixo, que se escolhe com a tecla F10
nos builds de depuração (ver "Câmara" em "Para quem programa"). Depois do playtest de 22/11, em que
alguns jogadores tiveram dores de cabeça e enjoo com a câmara das zonas, o nível 1 começa com a de
zoom fixo (`Fixed`, Start Framing do `GameCamera` do nível; #284), mais suave do que no #282: zona
morta de 96 px para cada lado em vez de 28, mola a 6 /s em vez de 8, antecipação de 3 % da largura
em vez de 5 %, trocada mais devagar (1,5 /s em vez de 3), o homem 12 % abaixo do centro em vez de
25 % e, numa queda, 30 % acima do centro em vez de 15 %, para se ver mais do que está por baixo
(valores no `fixed_framing_stats.tres`). Com a zona morta maior do que a antecipação (3 % da largura
são 41 px do mundo), a correr o homem fica 55 px do mundo à frente do centro do ecrã, cerca de 77 px
no ecrã: vê-se um pouco mais do caminho que fica para trás, de onde vêm os cães, do que do que está
à frente. É uma troca escolhida para o ecrã se mexer menos; para o ecrã antecipar de facto, o Look
Ahead teria de subir para perto de 0,1, com mais movimento. Ficaram as regras do #282, que o `test_fixed_framing.gd`
verifica: um salto completo não mexe o ecrã, e um segundo de queda mostra pelo menos mais 200 px
por baixo dos pés (com Fall Delay a 0,25 s a descida de um salto contava como queda, e com Max
Speed a 1200 px/s a câmara não acompanhava a queda, por isso ficaram em 0,35 s e 2000 px/s). A
tabela seguinte descreve a forma com as zonas.

| Técnica | Comportamento | Medida |
|---|---|---|
| Janela | a câmara só se desloca quando a personagem sai de um retângulo à volta do ponto que segue: 64 px para cada lado, 250 px acima e nenhum abaixo | um salto completo (240 px) e o balanço numa chaminé de 120 px (72 px) não movem a câmara |
| Suavização | em cada passo, a câmara percorre uma fração da distância que falta, independente da frequência de imagem | 95 % da distância em 0,5 s |
| Antecipação | a câmara mostra 300 px a mais do lado para onde a personagem corre e só troca de lado depois de a personagem recuar 180 px a partir do ponto mais afastado | em corrida, 1,67 s de percurso visível à frente; a troca de lado conclui-se em cerca de 1,2 s, sem ultrapassar a posição final |
| Reenquadramento | ao pousar num chão mais alto, a câmara centra-se nesse chão | numa escada de degraus de 200 px, a câmara sobe um degrau de cada vez |
| Olhar para baixo | numa queda superior a um salto completo, a câmara mostra 400 px a mais abaixo da personagem | à velocidade máxima de queda, 0,51 s de queda visível abaixo dos pés |
| Zonas | enquanto a personagem está numa zona de câmara, o ecrã não mostra nada acima nem abaixo dela e, com o limite horizontal ligado, nada para os lados | a correr para uma borda de uma zona com o limite horizontal ligado ou a cair para o fundo de uma zona, o ecrã para na borda; junto a uma parede, depois de uma inversão de sentido, o ecrã só se desloca quando a personagem se afasta o suficiente para precisar da antecipação (a partir de 200 px da parede, 0,9 s depois da inversão) |
| Passagem entre zonas | ao mudar de zona, a câmara desloca-se como uma mola criticamente amortecida: parte da velocidade que já tinha e, a partir do repouso, começa devagar, acelera e para sem ultrapassar o destino, no máximo a 2000 px/s | uma passagem de 300 px fica 95 % concluída em 0,80 s; numa passagem de 1920 px, o primeiro passo é de 9 px, e não de 33 px, a velocidade máxima, como acontecia antes da mola |
| Margem inferior | a margem inferior de uma zona (Bottom Margin) deixa o ecrã mostrar mais abaixo dela, sem alterar o espaço que a zona ocupa | com 96 px, o fundo do ecrã fica 96 px abaixo do fundo da zona |
| Zoom ao parar | parada no chão, sem pedir corrida, durante 1,5 s, a câmara fixa-se na personagem (a antecipação volta a zero) e aproxima-se para um zoom de 1,25; ao voltar a andar, regressa ao zoom normal e à antecipação, sempre como uma mola | 1 s depois de parar, zoom 1,000 e antecipação de 299 px; depois de assentar, zoom 1,250 e antecipação de 0 px; a andar de novo, zoom 1,000 e antecipação de 299 px |
| Zoom por zona | cada zona pode ter o seu zoom (Zoom, no Inspector da zona), para um túnel ou um corredor encher mais o ecrã; a câmara passa para ele como uma mola, e a antecipação encolhe na mesma proporção, para a personagem ficar à mesma distância da borda do ecrã | numa zona com zoom 1,4, o zoom chega a 1,3998 com passos de 0,0061, no máximo, por frame, e a antecipação passa de 300 px para 214 px; parada nessa zona, o zoom fica em 1,749 (1,4 × 1,25) |
| Zoom à altura da zona | com a opção Fit Height ligada, numa zona mais baixa do que o ecrã, a câmara aproxima-se até a zona, a sua margem inferior e uma folga de 96 px por cima (a altura da personagem, para a cabeça não sair do ecrã num salto) encherem a altura do ecrã, no máximo até ao zoom 2 | numa zona de 400 px de altura com margem de 96 px, o zoom fica em 1,824 e o ecrã mostra exatamente da folga acima da zona até ao fim da margem; numa zona de 200 px, o zoom para em 2,0, com o fundo do ecrã no mesmo sítio |
| Zoom automático | com a opção Auto Zoom ligada (por omissão) e a câmara a conhecer os tiles do nível (Level Tiles, ou, se ficar vazio, a primeira camada de tiles com colisão do nível), numa zona com outra passagem por cima, separada por rocha, a câmara aproxima-se só o necessário para essa passagem deixar de se ver; uma abertura para fora da zona, como um poço que sobe do corredor, continua visível; no máximo até ao zoom 2; o zoom da própria zona funciona como mínimo | num corredor com outra passagem por cima, atrás de quatro filas de rocha, o zoom fica em 1,607 e o topo do ecrã coincide com o fundo da passagem; com o ar a subir diretamente do corredor, o zoom fica em 1 |
| Âncora horizontal | com o limite horizontal ligado, numa zona mais estreita do que o ecrã, a âncora horizontal (Horizontal Anchor) escolhe onde fica o ecrã: com 1, a borda direita do ecrã coincide com a borda direita da zona e o excesso aparece à esquerda; com 0, o contrário; com 0,5 (por omissão), divide-se pelos dois lados | numa zona de 600 px de largura, com a âncora a 1, a borda direita do ecrã fica exatamente na borda direita da zona; com 0, a borda esquerda na borda esquerda |
| Margem das bordas | se o corpo da personagem chegar a menos de 17 % do tamanho do ecrã de uma borda (184 px em cima e em baixo, 326 px dos lados), a câmara acompanha-o de imediato, sem esperar pela suavização, dentro dos limites da zona; durante a passagem entre zonas vale só na vertical, para a passagem lateral continuar suave | numa subida súbita de 600 px, logo no passo seguinte a cabeça está a 183,6 px do topo do ecrã |
| Corpo sempre no ecrã | na vertical, a câmara desloca-se sempre o necessário para o corpo inteiro da personagem ficar no ecrã, mesmo que isso passe o limite de uma zona: uma câmara atrasada numa subida rápida, ou uma zona com o topo baixo demais, nunca cortam a cabeça. Na horizontal, o mesmo acontece enquanto a câmara muda de zona, se a personagem estava no ecrã e se deslocou, mas não ao entrar num miradouro, cuja Vista pode ficar ao lado da personagem; uma personagem que avança mais de 200 px num só passo foi colocada, não se deslocou, e a câmara continua a chegar até ela de forma suave. Dentro de uma zona, o lado da zona pode cortar até metade do corpo, antes de a personagem passar para a zona seguinte | com os pés 20 px abaixo do topo de uma zona ancorada em cima, a cabeça fica 76 px acima da zona, e o topo do ecrã sobe exatamente até ela; a correr a 720 px/s para um poço com zoom 2 e a parar a 120 px do lado oposto, o corpo chegava a ficar 205 px fora do ecrã e passou a ficar sempre dentro |
| Limite horizontal | com a opção Limit Horizontally desligada (por omissão), a zona limita o ecrã só em cima e em baixo, e na horizontal a câmara segue a personagem como fora das zonas; ligada, limita-o dos quatro lados, para uma sala em que a câmara deve ficar parada | numa zona de 1200 px de largura, com a personagem a 1100 px da borda esquerda, a câmara fica no centro da zona (x 600) com a opção ligada e acompanha a personagem (x 1036) com a opção desligada, com o mesmo enquadramento vertical |
| Âncora vertical | numa zona mais baixa do que o ecrã, a âncora da zona escolhe onde fica o ecrã: em baixo (1), o fundo do ecrã coincide com o fundo da zona; em cima (0), o topo do ecrã coincide com o topo da zona; ao centro (0,5, o valor por omissão), o excesso divide-se pelos dois lados | numa zona de 400 px de altura, o ecrã mostra 680 px acima da zona com a âncora em baixo e 340 px de cada lado com a âncora ao centro; numa zona mais alta do que o ecrã, a âncora não altera a posição da câmara |
| Cenas de câmara | uma cena de câmara (`CameraCutscene`) leva a câmara a mostrar, por ordem, os enquadramentos (`CameraShot`) que tem como filhos, cada um com uma Vista (um `ReferenceRect` filho), um tempo de viagem e um tempo de paragem, e volta depois à personagem; começa quando a personagem entra pela primeira vez na sua zona de câmara (Trigger Zone), quando outro elemento a pede, como um desbloqueador, ou quando acaba uma conversa com a deixa escolhida (Talk Cue), como a oferta da Asmodeu; o mundo continua a correr, mas a personagem fica parada, sem crucifixo e sem receber golpes; o que está no caminho da câmara acorda antes de ela lá chegar (ver "Atividade fora do ecrã"); a câmara desloca-se com aceleração e travagem suaves e muda o zoom em proporção constante; um enquadramento com Keep Zoom mantém o zoom que a câmara tinha e só a centra na Vista; entre dois sítios que não cabem no mesmo ecrã, pode afastar-se a meio caminho até os dois caberem (Zoom Out To Travel); com Motion Blur, a imagem arrasta-se na direção da deslocação, tanto mais quanto mais depressa, até Max Blur, num ecrã por cima do nível e por baixo dos menus (`MotionBlur`, na câmara); cada enquadramento avisa quando a câmara lá chega (arrived), para um portão fechar ou abrir à vista; com um evento (Event), só se vê uma vez em todo o jogo, e o jogo grava nesse momento, como com um upgrade aceite, para uma morte não a repetir; sem evento, vê-se sempre que é pedida, como a do desbloqueador B do nível 1, também depois de cada morte; com uma fase de repetição (Replay Phase) e um evento de repetição (Replay Event), uma cena já vista volta a ver-se uma única vez, quando o nível recomeça nessa fase depois da primeira morte nela, passado o tempo de Replay Delay (0,8 s, para o ecrã já ter voltado do negro); as mortes contam-se nas estatísticas da partida (`RunStats`), que uma morte não desfaz, e o evento de repetição grava-se no momento, para a segunda morte não a repetir; é o caso da cena da fase 2 do nível 1, que volta a mostrar o portão B a fechar; o salto termina-a, passado meio segundo | uma viagem de 1 s chegou ao enquadramento em 59 passos de física (60 previstos); entre duas Vistas a 24 000 px uma da outra, com zooms de 1,2 e 0,6 nos extremos, a câmara afastou-se até ao zoom 0,070 a meio; com Keep Zoom, o zoom não mudou (diferença abaixo de 0,0001); com Motion Blur 0,5 e Max Blur 30 px, o arrastamento chegou a 30 px durante a viagem e foi 0 na paragem e no fim; um elemento adormecido junto da Vista acordou dois frames depois do início, antes de a câmara chegar; a cena da fase 2 do nível 1 durou 3,00 s; com o nível recomeçado na fase 2, não se repetiu sem mortes nessa fase, repetiu-se depois da primeira, 47 passos de física após o recomeço (48 previstos), e não se repetiu depois da segunda; a cena do desbloqueador B, de 3 s, viu-se nas três cópias seguidas do nível, sem mudar o zoom (diferença abaixo de 0,001); no fim, a câmara ficou exatamente onde estava antes de começar |
| Conversas em cena | quando um balão de diálogo começa (#284), entram barras pretas em cima e em baixo, por cima do nível e por baixo do balão (camada 7), com a proporção dos filmes em ecrã largo, 2,39:1 (cada barra com 12,8 % da altura): deslizam com travagem ao entrar (0,8 s) e com aceleração ao sair (0,6 s); a barra de alma esconde-se, como já acontecia; a câmara deixa a personagem e enquadra-a com quem lhe fala (`TalkFraming`, na câmara), num movimento de 1,4 s que começa e acaba devagar, com os pés logo acima da barra de baixo e as cabeças abaixo da roda das respostas, até ao zoom 2,0; o zoom pára onde as cabeças passariam para trás da roda, medido a partir das figuras desenhadas das duas personagens (o retângulo de cada imagem); com as barras de 2,39:1 há 304 px livres entre a roda e a barra de baixo: a conversa com a Velvet fica no zoom 2,0 e a da Asmodeu, mais alta, abaixo dele; a Asmodeu aparece a 300 px da personagem, para as duas figuras se lerem como duas, à direita ou, se aí a figura dela ficar dentro da rocha, como no fundo do poço da fase 2, à esquerda e espelhada para olhar para a personagem (`appear_clear_of`); uma conversa que comece enquanto a câmara volta de outra parte de onde a câmara está e, no fim, volta à posição de antes da primeira, contando com o que a personagem andou entretanto; o plano mantém-se parado 2 s e só depois a câmara se desvia 10 % da largura do ecrã para quem tem a vez (o demónio enquanto fala, a personagem quando aparecem as respostas); durante a conversa a personagem não recebe golpes e nenhum cão começa um ataque; ao fechar o balão, as barras saem e a câmara volta em 1,2 s, com a mesma suavização, à posição e ao zoom que tinha sobre a personagem, contando com o que ela se tenha mexido, e só então é devolvida; uma cena de câmara que comece durante esse regresso toma a câmara no sítio onde está; uma cena de câmara que comece no fim da conversa, como a da fase 2 depois da oferta da Asmodeu, parte do plano da conversa e volta à posição e ao zoom que a câmara tinha sobre a personagem antes da conversa; com Reduce Motion a conversa não muda a câmara, que continua a seguir a personagem como fora dela, e as barras aparecem por fade (0,2 s), com a altura toda; com Show Bars desligado não há barras; até haver ecrã de opções, estes dois valores mudam-se no Inspector do nó `TalkFraming`; numa conversa durante uma cena de câmara, a câmara e a proteção ficam com a cena, e uma proteção que já estava ligada antes da conversa (por exemplo, a personagem agarrada) continua ligada depois | barras de 138,2 px a 1080 px (12,8 % da altura); conversa com a Velvet ao zoom 2,0, com as duas figuras entre a roda e a barra; a câmara não se mexeu (0,000 px) nos primeiros 1,8 s do plano e depois desviou-se 96,0 px do nível para cada lado (192 px do ecrã ao zoom 2,0); no fim, 1,2 s depois de fechar o balão, a câmara estava a 0,002 px da posição de antes e no zoom 1,000 de antes; fundo da roda em y 613,6; com o zoom máximo subido para 4,0, o plano da Asmodeu parou em 1,971, os 304 px livres a dividir pelos 154 px das duas figuras; uma cena de câmara no fim da conversa terminou no zoom 1,249, o de antes da conversa (1,971 durante a conversa), e a 0,002 px da posição de antes; com Reduce Motion, a meio do fade as barras tinham a altura toda e opacidade 0,50, e a câmara nunca saiu da personagem |
| Miradouros | antes de uma queda, de uma subida ou de um entroncamento, um miradouro (`CameraLookout`) afasta a câmara para mostrar esse troço: enquanto a personagem estiver no retângulo do miradouro, e depois durante o salto ou a queda até aterrar, o ecrã enche a Vista (um `ReferenceRect` filho) e nunca mostra nada fora dela, pelo que a Vista se desenha só sobre esse troço do caminho; tem prioridade sobre as zonas; no chão, deixa de valer quando o corpo fica a mais de um tile (48 px) do retângulo | numa Vista de 2400 × 1350 px, o zoom fica em 0,8 e o ecrã coincide com a Vista; numa Vista de 6000 × 5000 px, o zoom para em 0,7 e o ecrã segue a personagem sem sair dela; ao sair de um rebordo, o miradouro mantém-se durante toda a queda e acaba na aterragem |

As zonas de câmara definem-se na cena de cada nível (ver "Câmara" em "Para quem programa"). Cada
zona é formada por um ou mais retângulos, e enquanto a personagem estiver dentro de um deles o ecrã
fica limitado, em cima e em baixo, à caixa que os envolve, e também dos lados se a zona tiver o
limite horizontal ligado. As zonas podem sobrepor-se: onde se sobrepõem, conta aquela em que a
personagem entrou por último, como nas zonas de bloqueio do Hollow Knight, pelo que a câmara muda
logo à entrada da zona nova; ao sair dela, volta à que ainda contém a personagem. Se entrar em duas
ao mesmo tempo, conta a de menor área, pelo que duas zonas sobrepostas não devem ter a mesma área. Fora de
todas as zonas, a câmara usa os seus próprios limites, os do nível inteiro, e segue a personagem
livremente. Uma zona do tamanho do ecrã, com o limite horizontal ligado, fixa a câmara. A sala de
teste tem uma única zona, do tamanho da sala, para que a câmara siga a personagem em todo o lado.

Numa sala mais alta do que o ecrã, uma zona que termina no chão da sala impede a câmara de mostrar a
rocha por baixo do chão: com a personagem no chão, o fundo do ecrã fica no limite da zona e o resto
do ecrã mostra a sala por cima. Numa sala ou num túnel mais baixo do que o ecrã, o ecrã mostra
sempre algo fora da zona, e a âncora vertical (Vertical Anchor, no Inspector da zona) escolhe de que
lado: com a âncora em baixo e o fundo da zona um tile (48 px) abaixo do chão, vê-se esse tile de
chão e o restante espaço fica acima.

Na caverna do nível 1 (`LustLevel_Phase1_Cave`), as 27 zonas estão no nó `CameraZones`. Seis
(1, 4, 8, 10, 16 e 30) foram afinadas à mão e serviram de modelo às restantes, com três tipos:

| Tipo | Retângulo | Valores |
|---|---|---|
| Sala | o ar da sala, um tile de rocha por cima e o fundo um tile abaixo do chão | âncora em baixo, margem inferior de 96 px, Zoom 1,3 e Auto Zoom |
| Túnel baixo | o mesmo | como a sala, com Fit Height e Zoom 1,45 |
| Poço vertical | o poço com dois tiles de rocha de cada lado, a entrar pouco na sala de baixo, sem que um salto a partir do chão dela a alcance | limite horizontal ligado, âncora horizontal com a borda do ecrã do lado de dentro do nível, para o excesso do ecrã mostrar a parede, Zoom 2, sem Auto Zoom e margem inferior de 200 px |

Com a personagem parada num chão, ficam três tiles de chão à vista no fundo do ecrã. O
`test_lust_phase1_zones.gd` verifica que duas zonas sobrepostas nunca têm a mesma área, que todos os
647 tiles onde a personagem pode estar de pé ficam dentro de uma zona e que, no início, o fundo do
ecrã fica três tiles abaixo do chão.

As fases 2 e 3 seguem as mesmas regras, com 14 zonas cada, numeradas pela ordem do caminho, e 5 e 6
miradouros. Cada sala, túnel ou poço tem a sua zona, com os valores da tabela. Numa sala, o limite
horizontal só se liga quando, sem ele, o ecrã mostraria outro caminho do outro lado de uma parede.
Numa sala ou num poço mais estreito do que o ecrã, a âncora horizontal põe a borda do ecrã do lado de
dentro do nível, e o excesso do ecrã mostra a parede, que pode ver-se: no poço que sobe da sala
inicial da fase 3, o ecrã mostrava 431 tiles de ar das salas ao lado e, com a âncora trocada, deixou
de mostrar algum. Num poço encostado à borda do nível, a câmara não passa a borda, pelo que o ecrã
ainda mostra parte do interior: no poço da fase 2 junto à borda esquerda, 90 tiles de ar em vez de
144. Na fase 2, os dois poços paralelos que descem da sala da saída têm âncoras opostas (1 e 0), para
cada um esconder o outro. Um
poço que se abre a meio de uma passagem começa um tile abaixo do chão dela, para a câmara mudar quando
a personagem cai nele, e não quando salta por cima. Os miradouros ficam antes dos buracos, das
travessias, das subidas e dos cruzamentos e mostram esse troço, mas não o que vem a seguir: antes das
pedras sobre o vão do meio da fase 2, por exemplo, o ecrã afasta-se para o zoom 0,91 e mostra as
pedras, o outro lado e o começo do vão, sem o fundo. Em cima de uma plataforma em movimento, a câmara
trata a personagem como se estivesse no ar, pelo que um miradouro dura a viagem toda. Duas zonas da
fase 3 fogem aos valores da tabela para não mostrarem outro caminho através de um chão fino: o túnel
por cima da sala inicial, cujo chão tem dois tiles, tem margem inferior de 48 px, e o corredor do fim,
encostado ao topo do nível, tem zoom 2,05, porque a 2 o ecrã mostraria uma faixa de 12 px do corredor
de baixo. O `test_lust_phase2_3_zones.gd` aplica às duas fases as verificações comuns e confirma que
nenhuma zona mostra outro caminho, com a personagem em qualquer ponto da zona e a câmara a antecipar
para os dois lados, nem o nível de baixo através do chão, que nenhuma zona com o limite horizontal
ligado mostra mais ar para lá dos seus lados do que mostraria com a âncora trocada, e que a
personagem começa numa zona ancorada em baixo.

A nova fase 2 do nível 1 (`scenes/levels/lust/lust_phase_2.tscn`, 142 × 257 tiles) é construída a partir do
texto `scenes/levels/lust/builders/lust_phase_2.txt` por `scenes/levels/lust/builders/build_lust_phase_2.gd`, que também coloca as 77
zonas de câmara. Todas têm o limite horizontal ligado, para que o ecrã só mostre outra passagem através
da rocha, que tem pelo menos 9 tiles entre passagens lado a lado e 6 entre passagens sobrepostas. O
`test_lust_phase_2.gd` aplica as mesmas verificações de câmara e confirma que cada portão só se alcança
depois do seu desbloqueador. O `test_lust_phase_2_route.gd` joga o nível do início ao fim, sem os cães,
com a personagem real: 107 movimentos, os dois desbloqueadores e a saída.

O nível 1 completo (`scenes/levels/lust/level1.tscn`, 371 × 379 tiles) junta numa só cena o tutorial, a nova fase 1 e a
fase 2, sem carregamentos entre elas. A primeira versão foi construída a partir do texto `scenes/levels/lust/builders/level1.txt`
por `scenes/levels/lust/builders/build_level1.gd`, que acrescenta as 124 zonas de câmara e copia os avisos, a Velvet e o demónio do
corredor da cena onde o tutorial foi feito, que fica como estava. Desde então, a cena é o nível: os tiles, os cães,
os espigões, as plataformas e as zonas editam-se à mão no editor do Godot, tile a tile e peça a peça. O construtor
recusa-se a escrever por cima de uma cena que já existe; só o faz com a opção `-- --force`, que descarta as
edições feitas à mão (a arte e o fundo são preservados mesmo nesse caso). O contorno de pedras segue o mesmo
princípio: `scenes/levels/lust/builders/build_stone_rim.gd` gera-o uma vez a partir dos tiles (uma faixa por cada troço reto de
chão, teto ou parede e uma peça por cada canto, 2628 peças) e grava as peças na cena, onde passam a editar-se pedra
a pedra. O script também se recusa a escrever por cima das peças já gravadas, salvo com `-- --force`. Depois de uma
mudança grande nos tiles, volta a gerar-se o contorno com essa opção, o que descarta os retoques feitos às pedras. O tutorial liga à fase 1 por um corredor de 12
tiles, e a fase 1 liga à fase 2 por uma chaminé de 8 tiles de altura e 3 de largura. Dois pontos de gravação
definem onde a morte recomeça: depois do tutorial, no início da fase 1; dentro da fase 2, no início da fase 2. A
cópia da fase 2 tem três plataformas deslocadas um tile, porque deixavam exatamente a altura da personagem por
baixo da rocha e a podiam prender. O `test_level1.gd` aplica as verificações de câmara às 151 zonas (38 da fase 3), confirma as
ligações e os pontos de gravação e deixa os 99 cães (13 da fase 3) a patrulhar durante 5 s, sem que nenhum caia do seu chão. O
`test_level1_route.gd` joga, sem os cães, o caminho curto do início ao fim e depois o caminho longo da fase 1: 184
movimentos com a personagem real.

A fase 3 do nível 1 foi acrescentada à mesma cena, a partir do desenho do grupo no Miro, por
`scenes/levels/lust/builders/add_level1_phase3.gd`, que lê o texto `scenes/levels/lust/builders/level1_phase3.txt` (154 × 158 tiles) e o junta ao
nível tal como está, sem o reconstruir, para não perder as edições feitas à mão. Escava o ar e coloca 12 cães, o maior
cão, 181 tiles de picos (25 faixas nas paredes, rodadas 90°), 52 tiles de plataformas que desabam, três portões, dois
desbloqueadores, 38 zonas de câmara e um ponto de gravação no início da fase. Recusa-se a correr duas vezes e a
escavar um tile que não seja rocha. No fim da fase 2, uma porta leva a uma sala pequena e a um corredor até ao início
da fase 3; a saída do nível passou para o F da fase 3, com espaço de rocha guardado para a sala do chefe. Os portões 1
e 2 são alçapões, que deslizam para o lado; o desbloqueador 1 abre o portão 2, o desbloqueador 2 abre o portão 1, e o
maior cão abre o portão 3 quando a personagem se aproxima. O `test_level1_phase3.gd` confirma o conteúdo, quem abre
cada portão, que nenhum portão se salta, que cada alçapão desliza para dentro da rocha e que a saída está no F. O
`test_level1_phase3_route.gd` joga a fase sem os cães, com a personagem real: 84 movimentos, os dois desbloqueadores,
os dois alçapões e a saída.

Numa revisão contra o desenho, a sala do bloco suspenso, por cima da subida ao lado da sala verde, estava diferente.
O traçado do desenho tinha ligado o bloco ao degrau da esquerda, o que fechava a passagem desenhada por baixo do canto
do bloco, e tinha perdido a parede fina que desce do bloco até ao chão dos cães: o traçado só regista retângulos de
ar, e uma parede desenhada com um só traço não deixa nenhum. A subida dava assim diretamente para os cães, e o poço com
picos à esquerda do bloco não levava a lado nenhum. A correção muda 20 tiles: 12 de rocha passam a ar, abrindo a
passagem, e 8 de ar passam a rocha, formando a parede. O caminho passa a ser o desenhado: sobe-se, passa-se por baixo
do bloco para a esquerda, sobe-se o poço, com 3 tiles de largura, e desce-se do outro lado do bloco. Os picos no fundo
do poço ficaram com 1 tile em vez dos 2 desenhados: com 2, sobravam menos de 3 px entre os picos e a esquina do bloco
para saltar, e a verificação em papel não encontrava caminho. A zona de câmara da subida foi também corrigida: por um
erro de coordenadas, estendia-se 50 tiles para a esquerda, por cima da coluna da esquerda. A cena foi alterada com a
opção `-- --reshape`, que compara o texto da fase 3 de antes e de depois e só muda o que difere entre os dois (tiles,
picos de chão e zonas de câmara), e só onde a cena ainda está como o texto antigo a deixou, para não desfazer edições
feitas à mão. O contorno de pedras (10 pedras trocadas por 14), as rochas soltas (5 trocadas por 7) e as imagens do
fundo (12 123 píxeis) foram refeitos só em volta dos tiles alterados.

A fase 3 foi depois afinada à mão, no editor: 10 plataformas novas (38 tiles), uma das quais substitui uma que já
existia, 16 faixas de picos deslocadas, cinco delas encurtadas, uma faixa retirada e uma plataforma que desaba descida
um tile. A fase tem agora 165 tiles de picos, 24 faixas nas paredes. O texto da fase 3 passou a acompanhar a cena,
com estas alterações incluídas, para que o `test_level1_phase3.gd` compare a cena com ele; 13 faixas de picos ficaram
deslocadas por parte de um tile, e o texto põe-nas nos tiles mais próximos. O caminho do teste foi encontrado de novo
pela verificação em papel, que, para essas faixas, conta como pico cada tile em que tocam, e a personagem real
percorre-o. Duas zonas de câmara passaram a mostrar menos por baixo, para não deixarem ver o nível de baixo entre as
plataformas novas: a do salão desce 48 px em vez de 96, e a de cima do T não desce.

Para a fuga ao maior cão (#271), o caminho de volta do salão do fundo até ao portão 3 passou a servir também ao cão,
que tem de o seguir. A cena foi alterada com a opção `-- --reshape`, que agora troca também plataformas que desabam:
68 tiles mudaram. As 8 plataformas que desabam da coluna, entre o salão e o portão 3, passaram a fixas (28 tiles), para
que as que a personagem pisa ao subir continuem lá para o cão. A chaminé atrás do portão 3 passou de 3 para 4 tiles de
largura (12 tiles), para caber o corpo do cão (168 px). Dois blocos de 4 tiles de largura (28 tiles) dividem o fundo
oeste do salão em quatro degraus de 192, 192, 144 e 96 px, que a personagem alcança sempre sem parede e o cão salta;
antes eram dois, de 384 e 240 px. O contorno de pedras (8 pedras trocadas por 19) e as rochas soltas (33 trocadas por
71) foram refeitos à volta dos tiles alterados; uma pedra que o `--reshape` não reconheceu, e que ficou a flutuar
dentro da chaminé alargada, foi retirada à mão. Uma das plataformas tinha sido deslocada 1 px no editor; o
`--reshape` reconhece agora cada plataforma pelo tile em que está. O `test_level1_escape_loop.gd` verifica os
degraus, as plataformas e a chaminé na cena. Para obrigar a este caminho, a passagem por baixo do pilar, entre o
posto do cão e o F, ganhou o portão 4 (2 × 6 tiles, sobe para dentro do pilar), aberto pelo mecanismo 3, a meio do
corredor entre o poço e a chaminé. O `--reshape` não acrescenta portões, por isso os dois nós foram acrescentados à
mão na cena, e o mapa e o construtor passaram a ter o portão 4 e o mecanismo `w`. No topo da coluna, a plataforma
de sentido único à altura do corredor ganhou um tile e passou a encostar à rocha, porque o vão de 1 tile entre as duas
parava o cão maior (a perseguição de um cão pára onde o seu chão acaba), e o teto sobe um tile por cima dela, para a
arte do cão não roçar na rocha (de 144 para 192 px de vão). A verificação das zonas de câmara
que mostram o nível de baixo, no `test_level1.gd`, contava como rocha as plataformas de sentido único e o espaço por
baixo delas como nível de baixo; conta-as agora como ar, porque o ecrã vê através delas e o espaço por baixo é a
mesma sala. Deixou assim de apontar a zona da coluna, e baixou ou deixou de apontar cinco zonas das fases 1 e 2 pelo
mesmo motivo.

O caminho que este teste repete foi encontrado por uma verificação em papel, fora do repositório, que simula o
movimento da personagem fotograma a fotograma. A primeira versão divergia do jogo: aplicava a gravidade no fotograma
do salto, pelo que a personagem subia 218 px no papel e 240 px no jogo, e aceitava movimentos decididos por menos de
um pixel. A versão corrigida reproduz o jogo fotograma a fotograma e recusa uma aterragem com menos de 4 px do corpo
sobre o chão, a passagem a menos de 3 px de um pico, de 1 px de um teto ou de 0,1 px da esquina de uma rocha, e
admite que a personagem escorregue até 144 px por uma parede antes de saltar dela, como um jogador faz para acertar o
ritmo.

A arte da fase 3 segue a das fases 1 e 2 e entra só onde a fase 3 abriu a rocha, para não tocar nos retoques feitos à
mão no resto do nível. O mesmo script gera o contorno de pedras a partir dos tiles de antes e de depois da fase 3 e
acrescenta só as peças que diferem: 311 pedras novas; das antigas sai apenas uma faixa de chão, que agora continua
pela porta. Coloca também 334 rochas soltas nas três camadas do fundo, nos chãos e tetos que a fase 3 abriu, com as
regras medidas nas 850 rochas das fases 1 e 2: o tamanho das rochas de cada camada, uma rocha por cada 7 a 18 tiles
de chão ou de teto, consoante a camada, o quanto cada rocha se enterra no chão ou no teto e, para as mais distantes,
uma sala com pelo menos 7 tiles de altura. Uma semente fixa dá sempre as mesmas rochas. Numa cena que já tem a fase
3, como a atual, só a arte se acrescenta, com a opção `-- --art`; as duas formas dão as mesmas 645 peças. As duas
imagens do fundo foram repintadas na zona da fase 3 e mantêm todos os outros píxeis (ver Créditos). A luz de cada
ponto segue a quantidade de ar à sua volta, por uma curva ajustada à imagem da fase 2, que essa curva reproduz com um
erro médio de 7 em 255 níveis de cinzento. Nas fases 1 e 2, 99 das 113 zonas de câmara têm uma só das três cores do
fundo; na fase 3, as zonas foram agrupadas em blocos do tamanho das áreas de cor da fase 2, e cada bloco recebeu uma
dessas cores, diferente da dos blocos vizinhos.

Os dois poços por onde se desce do início da fase 3 foram depois alongados para o dobro: o poço ao lado do bloco
passou de 8 para 16 tiles de altura, e o poço com picos que se lhe segue, de 22 para 44. Em cada um, o troço entre as
duas paredes foi copiado por baixo de si mesmo, com as mesmas faixas de picos, que passaram de 2 para 4 e de 4 para 8.
Para que cada poço continue a acabar na mesma sala, a sala inicial, o bloco e o corredor para a fase 2 ficaram onde
estavam, e todo o resto da fase 3 desceu 30 tiles (1440 px) sem mudar de forma; por baixo da fase havia mais de 90
linhas de rocha livre. O texto da fase 3 tem agora 154 × 188 tiles, 178 tiles de picos e 30 faixas nas paredes. A cena
foi alterada por um script fora do repositório, que move cada peça com a parte do mapa a que pertence (tiles, cães,
picos, plataformas, portões, desbloqueadores, pedras do contorno, rochas do fundo, zonas de câmara e saída), estica as
quatro faixas de pedra das paredes dos poços e copia as seis faixas de picos; as imagens do fundo foram deslocadas da
mesma forma, píxel a píxel, com uma transição de 24 px onde começa cada troço copiado, para a luz não mudar de golpe.
Na verificação em papel, com o movimento atual da personagem, o poço grande mantém a margem que tinha: 9 fotogramas
para sair vivo para o fosso, contra 8. O poço do bloco ficou mais exigente: passam 16% das combinações testadas de
largar e voltar a carregar na direção, contra 67% antes, porque a última faixa de picos fica na parede onde se
aterra. A verificação passou também a contar como dúvida um toque numa parede a 19 px ou menos do seu topo, porque o
jogo levanta a personagem para cima de uma saliência que falha por até 16 px. O caminho do
`test_level1_phase3_route.gd` até aos dois desbloqueadores foi encontrado de novo, e a personagem real percorre-o. O
último troço, até à saída, é ainda o que foi gravado antes de o salto ficar mais pesado, e falha, como já falhava antes
desta alteração; a verificação em papel também não sobe, com o movimento atual, a chaminé da esquerda que leva ao F.

O poço ao lado do bloco foi depois alongado outra vez, para o triplo do que tinha: de 16 para 48 tiles. O troço novo,
de 32 tiles, entra entre o fundo do poço e a passagem por baixo dele, as únicas duas linhas do mapa por onde a parte de
cima da fase 3 toca no resto; a sala inicial, o bloco e o corredor para a fase 2 ficam onde estavam, e tudo o resto da
fase 3, incluindo a sala da Asmodeu, desceu 32 tiles (1536 px) sem mudar de forma. Uma primeira versão, uma queda
única com dentes de rocha com picos alternados de cada lado, não se passava na verificação em papel: à velocidade
máxima de queda, a personagem não tem tempo de atravessar o poço de um lado para o outro. A versão final divide a
queda em duas. Na primeira, um dente de rocha com picos encostado à parede esquerda obriga a cair pela direita, sobre
uma plataforma que desaba 0,6 s depois de a personagem lhe tocar; na segunda, uma estaca de rocha com picos junto à
parede esquerda obriga a contorná-la pela direita e a puxar depois para a esquerda, para aterrar antes do fosso com
picos que já existia. Duas faixas de picos na parede direita castigam quem se encosta a ela. Na verificação em papel,
a primeira queda passa para quem salta do bloco e larga a direção entre 64 e 168 px depois, e a segunda para quem larga
até 80 px depois da borda e volta a carregar na esquerda a qualquer momento durante cerca de 1 s; quem fica parado na
plataforma cai pela direita, contra os picos. A personagem real percorre o poço novo e chega aos dois desbloqueadores no
`test_level1_phase3_route.gd`. As pedras do contorno do dente e da estaca foram dispostas pelo próprio `StoneRim`, a
partir dos tiles novos, e a parede esquerda do poço passou a ter três faixas de pedra em vez de uma. O texto da fase 3
tem agora 182 × 220 tiles e 181 tiles de picos; ficou também sem o cão que tinha sido retirado da cena à mão.

Na fase 1, o poço com cães a meio do caminho passou de paredes irregulares a um poço de paredes direitas, com a
largura da boca (13 tiles), que se alarga no fundo numa câmara de 21 × 4 tiles; ficou com 78 tiles de rocha a mais e 74
a menos. No fim do corredor que acaba na subida para a parte de cima da fase, foi escavada uma cova de 5 tiles de
largura e 4 de fundo, onde se pode atirar com o crucifixo os cães que esperam ao pé da subida. As duas zonas de câmara
foram ajustadas para cobrir o que foi escavado, e a do poço passou a fixar o ecrã entre os seus lados, para não deixar
ver, do fundo, a sala ao lado. As pedras do contorno (50 retiradas e 22 novas) foram dispostas pelo próprio `StoneRim`
a partir dos tiles novos, e o fundo foi repintado só à volta das duas alterações, com a cor da zona onde ficam. O nível
tem três cenas de câmara, curtas e sem zoom, com um ligeiro arrastamento da imagem nas deslocações: à entrada da
primeira sala da fase 1, a câmara vai depressa até à saída, a chaminé que sobe para a fase 2, e volta (5 s ao todo);
na fase 2, quando acaba a primeira conversa com a Asmodeu, a câmara vai ao primeiro portão, que se vê fechar, e volta
(3 s); ao usar o desbloqueador desse portão, a câmara vai ao portão e ele abre à vista (4,6 s). As três só se veem uma
vez, e o salto termina-as. Uma primeira versão afastava a câmara sobre a fase inteira, durava 13,5 e 16 s e começava a
de fase 2 ao entrar na sala, ao mesmo tempo que a conversa, que imobiliza os cães: no caminho, viam-se cães parados.

O fundo da caverna (`level1_cave_map.png` e `level1_cave_shade.png`, um píxel por 8 px do mundo) estava desalinhado com
a rocha no tutorial e em quase toda a fase 1. Quando o poço S da fase 3 passou para o triplo, a imagem foi esticada 32
tiles (1 536 px) para baixo a partir do corte, mas até ao fundo da imagem e não só até ao fim da fase 3, nas colunas da
fase 3 (x de 2 400 a 11 136 px). Por isso, por baixo da fase 3, o ar aparecia escuro e a rocha iluminada, e via-se
uma costura vertical a x = 2 400 px, no tutorial. O fundo foi refeito a partir da versão anterior ao poço triplo, com o
esticão limitado às linhas da fase 3, e o repintado do poço da fase 1 foi aplicado outra vez por cima. Para o medir, a
diferença entre o brilho médio do fundo no ar e na rocha, numa escala de 0 a 255, no tutorial e na fase 1 (x até
11 000 px, y de 12 000 px até ao fundo): era 18 e passou a 116. Na fase 3 e na fase 2 o fundo ficou igual.

A mesma medida mostrou que a sombra (`Backdrop/Shade`, a imagem que multiplica o fundo) estava 183 px abaixo do sítio
onde a sua luz coincide com a rocha: tinha passado de y = −11 px para (−3, 172) num commit de 15 de novembro, sem razão
registada. Voltou a (0, −11). Com ela no sítio, a diferença entre ar e rocha passou de 55 para 96 na fase 2, de 84 para
107 na fase 3 e de 85 para 116 no tutorial e na fase 1: a luz fica no ar e a sombra junto às paredes.

| Medida em headless, sem o custo de desenhar | Fase 2 sozinha (33 cães) | Nível 1 antes da fase 3 (88 cães) |
|---|---|---|
| Recomeçar depois de uma morte (instanciar e entrar na árvore) | cerca de 25 ms | cerca de 90 ms |
| Física por fotograma, de 16,7 ms disponíveis | 2,6 ms | 4,8 ms |
| Restante processamento por fotograma | 2,0 ms | 3,3 ms |

Para afinar uma zona não é preciso mexer em código: no editor, selecionar a zona (ou um dos seus
retângulos) mostra a azul o que o ecrã pode mostrar nela e a branco um ecrã ao zoom dessa zona,
calculados pela câmara do nível. O desenho atualiza-se ao mudar os valores no Inspector ou ao
arrastar os retângulos.

O desenho dos níveis deve ter em conta quatro consequências deste comportamento:

- A fronteira entre uma zona fixa e uma zona em que a câmara segue a personagem deve ficar numa
  porta, num poço ou numa queda, e não no chão onde se anda. A passagem desloca a câmara até 900 px,
  e uma personagem que andasse para trás e para a frente sobre a fronteira faria a câmara ir e vir.
- Uma zona mais estreita do que o ecrã deixa ver a zona vizinha. Os ecrãs mais largos (21:9) mostram
  2520 px: nesses ecrãs, uma zona fixa de 1920 px mostra 600 px da zona ao
  lado. Na vertical, a âncora da zona escolhe se o que fica à vista é o que está por cima ou por
  baixo; na horizontal, o excesso divide-se sempre pelos dois lados.
- Em chaminés com mais de 228 px, a antecipação muda de lado a cada salto da parede, porque o
  balanço da personagem ultrapassa os 180 px do limiar. Estas chaminés já ficam fora do caminho
  obrigatório (ver "Medidas para o desenho de níveis").
- A zona escolhe-se pela posição dos pés da personagem. Até isso ser corrigido, a fronteira entre
  duas zonas empilhadas deve ficar pelo menos uma altura da personagem (96 px) acima de qualquer chão:
  com os pés logo abaixo da fronteira e a zona de baixo do tamanho do ecrã, a cabeça fica fora do
  ecrã, até 86 px.

Os valores da câmara estão no ficheiro `camera_stats.tres`, em `Projeto/scenes/others/camera/`, e editam-se no
Inspector do Godot, como os do movimento.

| Campo no Inspector | Valor atual | O que controla |
|---|---|---|
| Window Half Width | 64 px | a largura da janela para cada lado do ponto seguido |
| Window Up | 250 px | a altura da janela acima do ponto seguido; o salto completo e 10 px de margem |
| Edge Margin | 0,17 | a distância mínima do corpo da personagem às bordas do ecrã, em fração do ecrã, antes de a câmara a acompanhar de imediato; com 0, só fica a regra do corpo inteiro no ecrã |
| Window Down | 0 px | a altura da janela abaixo do ponto seguido; com 0, a câmara acompanha logo qualquer descida |
| Follow Sharpness | 6 /s | a rapidez da suavização |
| Look Ahead Distance | 300 px | a distância da antecipação |
| Turn Threshold | 180 px | o recuo necessário para a antecipação trocar de lado; acima dos 163 px de balanço na chaminé mais larga que se sobe apenas com o salto |
| Look Ahead Sharpness | 4 /s | a rapidez da troca de lado |
| Look Down Threshold | 250 px | a queda, abaixo do último chão, a partir da qual a câmara olha para baixo |
| Look Down Distance | 400 px | a distância do olhar para baixo |
| Look Down Sharpness | 10 /s | a rapidez com que a câmara olha para baixo e regressa |
| Zone Change Speed | 3000 px/s | a velocidade máxima da câmara ao passar para outra zona; acima da velocidade máxima de queda (1400 px/s), para nunca perder a personagem |
| Zone Change Sharpness | 10,1 /s | a rapidez da mola na passagem entre zonas; uma passagem de 300 px fica 95 % concluída em 0,38 s (com o valor de referência de 6 /s, em 0,80 s) |
| Idle Delay | 1,5 s | quanto tempo a personagem tem de estar parada para a câmara se fixar nela e se aproximar |
| Idle Zoom | 1,25 | quanto a câmara se aproxima com a personagem parada (o ecrã passa a mostrar 1536 × 864 px); multiplica o zoom da zona; com 1, nunca se aproxima |
| Zoom Sharpness | 2,5 /s | a rapidez da mola do zoom; uma mudança fica 95 % concluída em 1,9 s |
| Fit Headroom | 96 px | o espaço que o ecrã ainda mostra acima de uma zona com Fit Height |
| Max Zone Zoom | 2 | o zoom máximo a que o Fit Height ou o Auto Zoom de uma zona podem levar a câmara; a 2, o ecrã mostra 960 × 540 px; o zoom definido à mão numa zona não tem este limite |
| Min Lookout Zoom | 0,7 | o máximo que um miradouro pode afastar a câmara; a 0,7, o ecrã mostra 2743 × 1543 px; uma Vista maior é seguida por dentro |
| Lookout Zoom Sharpness | 2,5 /s | a rapidez com que a câmara se afasta ao entrar num miradouro |
| Lookout Change Sharpness | 3 /s | a rapidez com que a câmara se desloca para a Vista de um miradouro |
| Lookout Change Speed | 2500 px/s | a velocidade máxima dessa deslocação; com os três valores, ao fim de 2 s a câmara está 96 % afastada e 96 % deslocada, para a entrada se ler como um recuo e não como um salto, e quem passa depressa ainda vê o caminho |

### Tremor do ecrã

Nos momentos em que a personagem corre perigo, o ecrã treme por instantes: um golpe de um demónio ou
de um perigo (espinhos, uma pedra que lhe cai em cima), um agarrão, cada toque no Salto para se
soltar e a libertação, a morte, uma aterragem depois de uma queda longa, erguer e perder o
crucifixo, e uma pedra que se parte perto dela. Os toques para se soltar levam o tremor a um nível
fixo, sem o somar, para que carregar depressa dê um abanão por toque em vez de o acumular;
soltar-se mantendo o Salto premido (a opção Hold to escape) não faz tremer.
A libertação também leva o tremor a um nível fixo, o mais alto do agarrão, quer a personagem se
solte com toques quer mantendo o Salto; só a morte treme mais. Os
movimentos de todos os dias, como um salto ou uma aterragem normais, não fazem tremer o ecrã, nem o
crucifixo que o nível tira, ao começar, a quem já o perdeu. Cada momento acrescenta um
trauma entre 0 e 1, que desce sozinho; o tremor é o trauma elevado a 1,5, pelo que os momentos fracos
se notam menos do que os fortes, e momentos seguidos somam-se até ao máximo. Nenhum tremor dura mais de meio
segundo depois do último impacto. O ecrã desloca-se segundo um ruído contínuo, sem saltos ao acaso,
e nunca roda, para mexer o ecrã o menos possível. Junto à borda de um nível, um tremor forte mostra
até 48 px de fora do nível. No playtest de 22/11 os tremores não se sentiam (um golpe mexia o ecrã
8 px), e por isso subiram (#284): um golpe mexe-o 17 px e uma morte 48 px. Nas opções, Screen shake regula a força de 0 a 100 %, e 0 desliga o
tremor.

Os valores do tremor estão em `camera_shake_stats.tres` (`Projeto/scenes/others/camera/`) e os de
cada momento em `impact_stats.tres` (`Projeto/scenes/others/feedback/`):

| Campo no Inspector | Valor atual | O que controla |
|---|---|---|
| Max Offset | 48 px | o maior desvio do ecrã para cada lado, com trauma 1, em píxeis do ecrã |
| Decay | 2 /s | o trauma que desaparece por segundo; com 2, o trauma máximo acaba em 0,5 s, e o Inspector não aceita menos |
| Exponent | 1,5 | a potência do trauma; com 1,5, metade do trauma produz 35 % do tremor |
| Speed | 10 | a rapidez do tremor; cada unidade faz o ecrã passar pelo centro cerca de 1,35 vezes por segundo, ou seja, cerca de 13 com 10 (medido a 60 FPS) |
| Hit Trauma | 0,5 | um golpe de um demónio ou de um perigo |
| Grab Trauma | 0,2 | um agarrão, somado ao golpe que o inicia |
| Struggle Trauma | 0,45 | o nível a que cada toque no Salto para se soltar leva o trauma, sem o somar; abaixo do golpe, para que o golpe pese mais |
| Break Free Trauma | 0,9 | o nível a que a libertação de um agarrão leva o trauma, sem o somar; acima do golpe e do agarrão juntos (0,7) |
| Death Trauma | 1 | a morte, o momento mais forte, acima da libertação |
| Hard Landing Trauma | 0,45 | a aterragem depois de uma queda de 480 px ou mais, a mesma que tem o som forte |
| Crucifix Raised Trauma | 0,35 | erguer o crucifixo, uma vez, e nada enquanto está erguido |
| Crucifix Lost Trauma | 0,5 | perder o crucifixo |
| Rock Trauma | 0,55 | uma pedra que se parte junto à personagem |
| Rock Reach | 900 px | a distância a partir da qual uma pedra já não faz tremer o ecrã nem vibrar o comando; até lá, o trauma e a vibração descem em linha reta com a distância |

### Vibração do comando

Com comando, a vibração responde ao que o corpo da personagem sente: golpes, peso, esforço e medo.
Não responde à interface nem ao registo moral, que o jogo esconde do jogador. O comando tem dois
motores: o fraco, pequeno e rápido, dá um zumbido seco; o forte, grande e lento, dá um baque. Em cada
motor, a força e a rapidez da vibração andam juntas, e um motor pedido muito baixo roda devagar ou
nem arranca. Num comando real, um tique só no motor fraco, perto do mínimo que se sente, parecia
cócegas e, ao fim de algum tempo a jogar, deixava de se sentir. Por isso, os tiques do movimento dão
um baque curto no motor forte, abaixo do golpe de um demónio ou de um perigo, com um pouco do fraco
por cima.

Os momentos estão organizados numa escada de quatro degraus, pela frequência e pela importância de
cada um. Assim, os mais frequentes ficam leves e os raros e graves destacam-se:

| Degrau | Frequência | Como vibra | Momentos |
|---|---|---|---|
| Tique | muitas vezes por minuto | curto, até 0,1 s; os do movimento com um baque no motor forte, abaixo do golpe de um demónio ou de um perigo | salto, aterragem curta, cabeça no teto, encostar a uma parede, cada toque para se soltar, algo que entra na luz do crucifixo |
| Golpe | algumas vezes por minuto | os dois motores, o forte abaixo de meio, e desce depressa | golpe de um demónio ou de um perigo, agarrão, libertação, aterragem depois de uma queda longa, erguer o crucifixo, o crucifixo a esgotar-se |
| Grave | raro, com consequências | o motor forte a meio ou mais, e desce devagar | morte, perder o crucifixo, pedra que se parte junto à personagem; nos picos letais, a morte começa com uma picada |
| Contínuo | enquanto dura um estado | baixo, até 0,4 em cada motor, a pulsar | agarrado, enquanto a personagem afunda; o crucifixo erguido |

Só os momentos graves usam o motor forte a meio ou mais, e a morte é o mais forte nos dois motores e
o mais longo. Nos picos letais, a morte começa com uma picada curta e seca no motor fraco, acima da
da morte, que se sente antes de o motor forte, mais lento, encher. É o único impulso acima da morte,
porque faz parte dela. A aterragem cresce com a altura da queda, desde o tique da aterragem mais
curta que se ouve até ao golpe de uma queda longa: é a mesma altura que escolhe o som. Cresce
devagar nas quedas curtas dos saltos de todos os dias e depressa perto da queda longa, para que só
esta chegue ao motor forte. Cada toque para se soltar começa a 80 % e fica mais firme à medida que a
personagem se aproxima de se soltar. É o tique mais forte, porque vem por cima da vibração contínua
do agarrão, que esconde um tique leve, e não passa da morte no motor fraco. A dez toques por
segundo, cada toque acaba antes do seguinte, pelo que os toques se sentem separados. Os golpes e os
momentos graves descem até zero na parte final da sua duração, como uma pancada que se apaga, em
vez de pararem de repente.

A vibração contínua pulsa, para não se tornar um zumbido liso. Começa num nível que ainda se sente,
porque um motor pedido muito baixo mal roda. A do agarrão corre sobretudo no motor forte e cresce
enquanto a personagem afunda. A do crucifixo corre no motor fraco e cresce durante o aviso de que o
crucifixo vai baixar, ao mesmo tempo que a luz pulsa. Se a carga se esgotar, a vibração do
crucifixo dá lugar a um impulso que desce até zero ao longo de meio segundo, em vez de parar de
repente, e assim o bloqueio sente-se sempre; largado antes, o crucifixo baixa sem impulso. Cada vez
que algo que o crucifixo empurra entra na luz dele, como um cão que corre para a personagem, vibra uma pancada curta no motor
fraco, por cima da vibração contínua. Vários a entrar no mesmo instante dão uma só pancada, e o
desbloqueador de um portão, que já não responde ao crucifixo, não dá nenhuma. Depois da
morte, o crucifixo fica erguido até a sala recomeçar, mas o que ele faz já não vibra. Um impulso faz
a vibração contínua descer a 30 % só nos motores que ele usa, para que se sinta por cima dela, e ela
volta a subir à medida que o impulso desce. Assim, os toques para se soltar, só no motor fraco, não
escondem o afundar. Quando dois impulsos se juntam, cada motor fica no mais forte, sem os somar. A
libertação e a morte acabam a vibração contínua do agarrão; o crucifixo baixado e a morte acabam a
do crucifixo.

Só vibra o último comando usado, e nenhum enquanto se joga com o teclado. O comando em uso passa de
um nível para o seguinte. A pausa e sair da janela do jogo param a vibração de imediato e descartam os
impulsos. A vibração contínua volta quando o jogo continua, porque o estado continua. Sair do nível
para tudo.

Nas opções, Vibration regula a força de 0 a 100 %, e 0 desliga-a. Cada mudança do slider toca a
vibração de um golpe no último comando usado, mesmo que o slider se mude com o rato, para o jogador
sentir a força que escolhe. Se o slider for arrastado com o rato, toca uma vez, quando é largado.
Constant vibration desliga só a vibração contínua, para quem aceita os impulsos mas não um zumbido
prolongado. Os momentos têm também imagem ou som. O aviso de que o crucifixo vai baixar vê-se na luz
dele, que pulsa, e ouve-se no som, que treme com ela (ver "Crucifixo").

No jogo exportado, a vibração depende de uma definição do projeto: Project Settings › Editor ›
Export › Convert Text Resources To Binary está desligada (#284, `test_export_settings.gd`). A 20/11,
com ela ligada, o `.exe` só vibrava nos menus: os 18 impulsos que o `rumble_stats.gd` cria como
valores por defeito chegavam vazios ao jogo exportado (o salto, o golpe e a morte saíam `null` num
build de diagnóstico), e com ela desligada chegaram. O motivo exato da perda na conversão é uma
inferência nossa. O custo é o jogo exportado levar as cenas e os recursos em texto, maiores e mais
lentos de carregar, ainda por medir. A alternativa, que não mexe no projeto todo, é gravar os 18
impulsos no próprio `rumble_stats.tres`. Fica a decisão do grupo.

Os valores estão em `rumble_stats.tres` (`Projeto/scenes/others/feedback/`), agrupados no Inspector
pelos degraus. Cada impulso tem o motor fraco e o forte, de 0 a 1, a duração e a parte final em que
desce até zero (Fade, de 0 a 1). São valores de referência, a afinar com um comando com motores:

| Campo no Inspector | Fraco | Forte | Duração | Fade | O momento |
|---|---|---|---|---|---|
| Jump | 0,2 | 0,4 | 0,1 s | 0,5 | um salto, do chão ou de uma parede: um baque curto, que desce na segunda metade |
| Landing | 0,15 | 0,3 | 0,08 s | 0,5 | a aterragem mais curta que se ouve, um baque mais leve do que o salto; uma queda mais longa aterra mais forte, até Hard Landing, ao longo de Landing Growth |
| Head Bump | 0,4 | 0,3 | 0,08 s | 0,5 | a cabeça no teto |
| On Wall | 0,25 | 0,25 | 0,07 s | 0,5 | encostar a uma parede |
| Struggle | 0,7 | 0 | 0,08 s | 0 | cada toque no Salto para se soltar: 80 % sem progresso (Struggle Start Share), 100 % perto de se soltar |
| Crucifix Struck | 0,5 | 0 | 0,08 s | 0 | algo que o crucifixo empurra entra na luz dele, como um cão; vem por cima da vibração contínua, por isso fica acima dos tiques do movimento |
| Hit | 0,5 | 0,45 | 0,16 s | 0,8 | um golpe de um demónio ou de um perigo; é também a amostra das opções; nenhum tique chega ao seu motor forte, nem na força nem no total ao longo do impulso, para o golpe de um demónio ou de um perigo pesar sempre mais do que um movimento |
| Grab | 0,3 | 0,35 | 0,2 s | 0,7 | o agarrão, logo a seguir ao golpe que o inicia |
| Break Free | 0,45 | 0,15 | 0,12 s | 0,6 | a libertação |
| Hard Landing | 0,35 | 0,45 | 0,16 s | 0,8 | a aterragem depois de uma queda longa, o topo das aterragens |
| Crucifix Raised | 0,4 | 0,1 | 0,12 s | 0,6 | erguer o crucifixo |
| Crucifix Ran Out | 0,5 | 0,15 | 0,5 s | 1 | o uso do crucifixo esgota-se com o botão premido: desce até zero ao longo de todo o meio segundo, no lugar da vibração contínua |
| Death | 0,7 | 1 | 0,6 s | 0,9 | a morte, o mais forte nos dois motores e o mais longo |
| Spike Death | 1 | 0 | 0,06 s | 0 | a morte nos picos letais, por cima da Death: uma picada curta no motor fraco, que se sente antes de o motor forte encher |
| Crucifix Lost | 0,35 | 0,75 | 0,45 s | 0,85 | perder o crucifixo, de vez |
| Rock | 0,3 | 0,7 | 0,3 s | 0,8 | uma pedra que se parte junto à personagem; mais longe, enfraquece na mesma proporção do trauma do tremor, até ao Rock Reach |

Landing Growth (2, de 1 a 4) diz como a aterragem cresce de Landing para Hard Landing com a altura
da queda: a 1, em linha reta; acima de 1, devagar nas quedas curtas e depressa perto da queda longa.

A vibração contínua tem os níveis completos, a parte com que começa e a pulsação:

| Campo no Inspector | Fraco | Forte | Começa em | Pulsação | O estado |
|---|---|---|---|---|---|
| Grab Sink | 0,2 | 0,4 | 60 % | 2 por segundo, desce 50 % | agarrado: 60 % no agarrão, 100 % à beira da morte |
| Crucifix Held | 0,35 | 0 | 60 % | 3 por segundo, desce 40 % | o crucifixo erguido: cresce até 100 % durante o aviso de que vai baixar (Warning Time, no `crucifix_stats.tres`) |

A descida da vibração contínua sob um impulso (30 %) está no nó `ControllerRumble` da cena da
câmara, no campo Sustain Duck Share.

## Fundo em camadas

O fundo de cada nível é formado por camadas a distâncias diferentes da câmara. Quanto mais distante a
camada, mais devagar se desloca no ecrã (efeito de parallax), o que dá profundidade ao cenário sem
desenhos adicionais. Na sala de teste, a camada distante desloca-se 0,25 px por cada pixel que a
câmara percorre e cobre o ecrã em qualquer ponto da sala, tanto nos ecrãs 16:9 como nos 21:9.

O fundo de cada nível parte do modelo `scenes/levels/background/level_background.tscn`, que já contém as quatro
camadas previstas, da mais distante para a mais próxima:

| Camada | Scroll Scale | Conteúdo | Cobertura do ecrã (Cover) |
|---|---|---|---|
| Far | 0,25 | uma imagem: as paredes da gruta, o céu | FIT: a imagem é ampliada o necessário para cobrir o ecrã em todo o nível; REPEAT, se tiver sido pintada para se repetir sem costura |
| Middle | 0,5 | peças soltas: rochas, torres | NONE: cada peça fica onde for colocada |
| Near | 0,75 | peças soltas, entre a camada intermédia e o plano de jogo | NONE |
| Front | 1,2 | peças escuras e desfocadas, à frente da personagem | NONE; é desenhada por cima do plano de jogo |

A Scroll Scale é a fração do movimento da câmara que a camada acompanha: com 1, a camada move-se com
o plano de jogo; com 0, fica parada no ecrã; acima de 1, passa mais depressa, como o que está mais
perto da câmara. Muda-se no Inspector de cada camada, também com o jogo a correr, no separador
Remote.

As imagens do cenário pintam-se em cinzentos. Cada camada tem a sua rampa de cor (campo Ramp), que
substitui os cinzentos pelas cores do nível: o quase branco toma a cor da ponta esquerda da rampa e
o quase preto a da ponta direita. As camadas mais distantes levam rampas mais escuras e menos
saturadas. Uma rampa é uma faixa PNG de 256 × 1 px, clara à esquerda e preta à direita, como a arte
as pinta, ou um GradientTexture1D com as cores do nível; uma rampa desenhada ao contrário, preta à
esquerda, usa-se com a opção Reverse Ramp. O Modulate de uma camada
ou de uma peça continua a tingir o resultado, o que permite, por exemplo, escurecer uma camada
distante. Uma peça pintada a cores fica numa camada sem rampa, ou com um material próprio, que a
camada respeita.

Para acrescentar arte nova ao fundo:

1. Exportar o PNG em cinzentos, com fundo transparente, para `Projeto/assets/sprites/backgrounds/`.
2. Abrir o fundo do nível, na pasta do nível. Um nível novo cria o seu com Scene › New Inherited
   Scene a partir de `Projeto/scenes/levels/background/level_background.tscn`, guarda-o na sua pasta
   e coloca-o como primeiro nó da cena do nível, para ficar atrás de tudo; a sala de teste usa
   `test_room/test_room_background.tscn`.
3. Arrastar o PNG para a camada da sua distância, onde passa a ser um Sprite2D.
4. Escolher a rampa da camada no campo Ramp.
5. Correr a cena do nível com F6 e confirmar a posição e as cores.

Uma peça solta aparece no centro do ecrã, quando a câmara está centrada num ponto P do nível, se
estiver colocada na sua camada na posição P × s + meio ecrã × (1 − s), em que s é a Scroll Scale da
camada; no ecrã de 1920 × 1080, meio ecrã é (960, 540). Por exemplo, numa camada a 0,5, uma torre que
deva aparecer com a câmara centrada em x = 4000 coloca-se em x = 4000 × 0,5 + 960 × 0,5 = 2480. O
editor mostra as camadas sem este deslocamento, pelo que a posição final se confirma a jogar.

## Afinação do movimento

Os valores do movimento estão reunidos no ficheiro `player_movement_stats.tres`, na pasta
`scenes/characters/player/` do projeto Godot (`Projeto/scenes/characters/player/` no repositório). Abre-se no painel FileSystem
do Godot e edita-se no Inspector. As alterações aplicam-se à personagem em todas as cenas.

| Campo no Inspector | Valor atual | O que controla |
|---|---|---|
| Max Run Speed | 600 px/s | a velocidade horizontal |
| Time To Max Speed | 0,18 s | o tempo de aceleração |
| Time To Stop | 0,15 s | o tempo de travagem e, por consequência, o deslize |
| Air Control | 0,7 | a fração da aceleração e da travagem do chão que se mantém no ar (1: igual ao chão; 0: nenhuma, e empurrar para o lado oposto deixa de soltar a personagem de uma parede) |
| Fall Gravity | 6600 px/s² | a aceleração da queda |
| Max Fall Speed | 1400 px/s | a velocidade máxima de queda |
| Jump Height | 240 px | a altura do salto completo |
| Time To Peak | 0,45 s | o tempo até ao ponto mais alto do salto |
| Min Jump Height | 80 px | a altura do salto mínimo; um toque sobe alguns px acima deste valor |
| Coyote Time | 0,1 s | o tempo, depois de sair de uma plataforma sem saltar ou de largar uma parede, durante o qual o salto ainda é aceite (0 desliga) |
| Jump Buffer Time | 0,1 s | o tempo durante o qual um salto pedido no ar fica guardado à espera de ser possível (0 desliga) |
| Ledge Assist Height | 16 px | quanto abaixo do topo de um degrau podem ficar os pés para a personagem subir para ele, ao cair contra a parede dele, a andar para ele ou só encostada; só nas paredes do nível, nunca num demónio nem numa plataforma de sentido único (0 desliga) |
| Wall Slide Speed | 350 px/s | a velocidade máxima de descida no deslize; a subida ao longo da parede não é travada |
| Wall Jump Lock Time | 0,2 s | o tempo, depois de um salto da parede, durante o qual a corrida não responde; com os valores antigos do movimento, 0,15 s ou menos deixava subir uma parede isolada, e com os atuais esse limite ainda não foi medido |

Os valores do crucifixo estão no ficheiro `crucifix_stats.tres`, na pasta `scenes/characters/crucifix/`, e editam-se
da mesma forma. O Speed Multiplier e o Repel Radius aplicam-se de imediato, também com o jogo a
correr, quando são mudados no separador Remote do editor; os restantes valores são lidos sempre que
são usados.

| Campo no Inspector | Valor atual | O que controla |
|---|---|---|
| Speed Multiplier | 0,25 | a fração da velocidade máxima que se mantém com o crucifixo erguido |
| Raise Buffer Time | 0,1 s | o tempo durante o qual um toque fica guardado enquanto o crucifixo não se pode erguer, como antes de aterrar ou no fim da espera (0 desliga) |
| Max Use Time | 5 s | a carga: o tempo máximo erguido a partir da carga cheia; cada segundo erguido gasta um segundo |
| Cooldown Time | 15 s | o tempo que a carga leva a encher de vazia a cheia com o crucifixo em baixo (cada segundo gasto volta em 3 s); se a carga acabar, o crucifixo fica bloqueado este tempo |
| Min Down Time | 0,35 s | o tempo mínimo em baixo depois de baixar com carga: toques rápidos erguem-no no máximo uma vez a cada 22 frames, menos de três vezes por segundo, o limite da WCAG 2.3.1 para a luz não piscar; um toque dado neste tempo fica guardado até ele acabar |
| Repel Radius | 200 px | a distância à qual os demónios e as almas perdidas são afastados, e o alcance da luz |
| Repel Speed | 1500 px/s | a velocidade a que são empurrados para fora desse raio |
| Heal Per Second | 5 SP/s | a cura por cada segundo com o crucifixo erguido |
| Warning Time | 1,5 s | o fim de cada uso em que a luz, o som e a vibração avisam que o crucifixo vai baixar (0 desliga o aviso) |
| Warning Pulse Rate | 2 por segundo | quantas vezes por segundo a luz pulsa durante o aviso; no máximo 3, o limite para quem tem epilepsia fotossensível |
| Warning Dim Depth | 0,6 | quanto a luz desce no fundo da última pulsação, no instante em que o crucifixo baixa (a 0,6, fica com 40 % do brilho); as pulsações anteriores descem menos |

Os valores dos SP estão no ficheiro `soul_points_stats.tres`, na pasta `scenes/characters/player/`. O Max SP e o Low
Threshold aplicam-se de imediato, também com o jogo a correr, quando são mudados no separador
Remote; os restantes valores são lidos sempre que são usados.

| Campo no Inspector | Valor atual | O que controla |
|---|---|---|
| Max SP | 100 SP | o máximo; a cura e a regeneração param aqui |
| Low Threshold | 25 SP | o valor a partir do qual, inclusive, a personagem fica com o SP baixo |
| Regen Delay | 3 s | a pausa da regeneração depois de cada golpe (0: sem pausa) |
| Regen Start Per Second | 0,5 SP/s | a velocidade da regeneração quando recomeça |
| Regen Top Per Second | 3 SP/s | a velocidade que a regeneração atinge no fim da subida e mantém depois |
| Regen Ramp Time | 10 s | a duração da subida de uma velocidade à outra (0: começa logo na mais alta) |

## Referências

- Game Accessibility Guidelines. (s.d.-a). *Avoid / provide alternatives to requiring buttons to be
  held down*. https://gameaccessibilityguidelines.com/avoid-provide-alternatives-to-requiring-buttons-to-be-held-down/
- Game Accessibility Guidelines. (s.d.-b). *Ensure controls are as simple as possible, or provide a
  simpler alternative*. https://gameaccessibilityguidelines.com/ensure-controls-are-as-simple-as-possible-or-provide-a-simpler-alternative/
- Keren, I. (2015, 11 de maio). *Scroll Back: The Theory and Practice of Cameras in Side-Scrollers*.
  Game Developer. https://www.gamedeveloper.com/design/scroll-back-the-theory-and-practice-of-cameras-in-side-scrollers
- Nystrom, R. (2014). *Game Programming Patterns*. Edição de autor.
  https://gameprogrammingpatterns.com/
- Pittman, K. (2016). *Math for Game Programmers: Building A Better Jump*. Game Developers
  Conference. https://www.gdcvault.com/play/1023559/Math-for-Game-Programmers-Building
- Reynolds, C. W. (1987). Flocks, herds and schools: A distributed behavioral model. *ACM SIGGRAPH
  Computer Graphics*, *21*(4), 25–34. https://doi.org/10.1145/37402.37406

## Para quem programa

### Estrutura

```
.                      raiz do repositório
├── LICENSE
├── README.md
└── Projeto/           raiz do projeto Godot
    ├── project.godot
    ├── main.tscn      cena principal: menus, pausa e o nível em jogo (script main.gd)
    ├── default_bus_layout.tres   buses de áudio
    ├── addons/        plugins de terceiros: o Dialogue Manager, que dá as falas
    ├── assets/        arte e som
    │   ├── audio/       som, por tipo: os efeitos sonoros em sfx/ e os ambientes em ambience/
    │   ├── fonts/       tipos de letra: a Tinos, de reserva para a Times New Roman dos menus, e a Atkinson Hyperlegible Next e a Literata dos avisos do tutorial
    │   ├── sprites/     uma pasta por grupo: player/, demon_lust/, environment/, backgrounds/, ramps/ e menu/ (a arte dos menus)
    │   └── ui/          imagens da interface: os ícones dos botões do comando nos avisos (prompts/)
    ├── dialogue/      as falas, um ficheiro .dialogue por nível
    ├── scenes/        cenas, scripts e ficheiros de dados, por tipo e, dentro de cada tipo, por sistema
    │   ├── autoload/    serviços globais: as opções do jogador (Settings), o registo moral (Moral), o progresso do jogo (GameState), as estatísticas da partida (RunStats), as tentações (Offers, em offers/, com o ritmo das ofertas por mortes), o último aparelho usado, teclado ou comando (LastDevice), a gravação e os perfis de controlos
    │   ├── characters/  a personagem (player/), o crucifixo (crucifix/), os demónios (demon/, com os estados em states/, e os que falam, Velvet e Asmodeu) e os componentes que mais de um sistema usa (components/)
    │   ├── levels/      uma pasta por nível: a sala de teste (test_room/), a sala de treino (gym/) e o nível 1 (lust/, com os construtores e os mapas em texto em builders/); na raiz, as peças e os scripts comuns e o fundo de que os níveis partem (background/)
    │   ├── objects/     peças com comportamento: portões (gates/), plataformas (platforms/) e armadilhas (traps/)
    │   ├── others/      câmara (camera/), atividade fora do ecrã (activity/, o ActivityTracker, que adormece o que está parado longe do ecrã), som ambiente (ambience/, as camadas de sons soltos, os fundos e as brasas que o vento leva), depuração (debug/), resposta aos impactos (feedback/), todos os shaders (shaders/) e conjuntos de tiles (tilesets/)
    │   └── screens/     menus, ecrã das opções, o balão de diálogo, indicador de gravação e a barra de alma (soul_hud/)
    ├── tests/         testes automáticos (test_*.gd), que correm sem janela
    │   ├── launchers/ abrem o jogo num ponto escolhido, para ver à mão (por agora, o fim da fase 2)
    │   ├── measures/  medições, que imprimem números em vez de verificar resultados
    │   └── support/   preparação comum aos testes
    └── themes/        o tema comum da interface (ui_theme.tres)
```

O projeto segue a estrutura de pastas das aulas de Conceção e Desenvolvimento de Jogos (CDJ): a
arte e o som em `assets/`, as cenas e os scripts em `scenes/` e o tema da interface em `themes/`.
Dentro de `scenes/`, as pastas dividem-se por tipo e, em cada tipo, por sistema. Cada pasta de
sistema reúne a cena, os scripts e os ficheiros de dados (`.tres`) de uma parte do jogo, que se
encontram assim num único local, como recomenda a documentação do Godot
([Project organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)).
A arte é uma exceção: fica em `assets/`, separada das cenas que a usam, como pede a estrutura de CDJ.
Os shaders e os conjuntos de tiles são outra: ficam juntos em `scenes/others/`, por tipo, porque
servem várias partes do jogo e é por tipo que se procuram.

Para que a organização se mantenha à medida que o jogo cresce, seguem-se oito regras:

- Um sistema novo, como um demónio ou um menu, recebe a sua pasta dentro do tipo a que pertence, e
  um nível novo recebe a sua em `scenes/levels/`. As peças que qualquer nível pode usar ficam na
  raiz de `scenes/levels/`.
- `scenes/characters/components/` recebe apenas o que dois ou mais sistemas usam; o resto fica na
  pasta do sistema a que pertence.
- O que é global e não pertence a nenhum sistema, como o estado do jogo, as opções gravadas ou a
  gravação, fica em `scenes/autoload/`.
- Os shaders ficam todos em `scenes/others/shaders/` e os conjuntos de tiles em
  `scenes/others/tilesets/`, mesmo os que só um sistema usa.
- O som também se divide por tipo: os efeitos sonoros ficam em `assets/audio/sfx/`, os ambientes
  em `assets/audio/ambience/` (os sons soltos do vento em `wind/`, uma pasta por categoria) e os
  sons de coisas do mundo em `assets/audio/textures/`, uma pasta por coisa (o fogo em `fire/`, com
  o ciclo à raiz e os estalos em `crackles/`), e a música terá uma pasta sua ao lado destas.
- O que não faz parte do jogo fica em pastas à parte: os construtores de um nível, com os mapas em
  texto de que partem, em `builders/`, dentro da pasta do nível; em `tests/`, as medições em
  `measures/` e os lançadores em `launchers/`.
- Os nomes de pastas e de ficheiros usam minúsculas e `_` (snake_case). O sistema de ficheiros do
  jogo exportado (o PCK) distingue maiúsculas, mesmo num jogo exportado em Windows, cujo editor não
  as distingue: um caminho que só difere nelas funciona no editor e falha no jogo exportado (secção
  Case sensitivity da mesma página da documentação). Por agora há uma exceção, as cenas antigas
  do nível 1 (`LustLevel_*.tscn`).
- Um sistema não acede ao interior de outro: comunica por sinais ou por uma referência atribuída no
  Inspector, nunca por um caminho na árvore de nós.

Os ficheiros movem-se e renomeiam-se no painel FileSystem do editor, que atualiza as referências
entre cenas e recursos; no fim, uma pesquisa pelo caminho antigo em todo o projeto confirma que
nenhum script, incluindo os testes, ficou a apontar para ele.

A pasta `tests/` e as pastas `builders/` ficam à parte, para que a exportação as possa excluir com
um filtro por pasta. Os jogos exportados vão para `builds/`, na raiz do repositório, fora do projeto
Godot e do git.

A passagem para esta estrutura fez-se por script, em três commits. Em Windows, o git não distingue
maiúsculas (`core.ignorecase`), e o `git add` não vê uma mudança que só as troca. Por isso, o
primeiro commit tirou as cenas de `Lust/` antes de a pasta passar a `lust/`, e o nome antigo do
`Passadeira.png` saiu do índice (`git rm --cached`) antes de o ficheiro passar a `passadeira.png`.
O terceiro commit separou o que o segundo deixara misturado: os shaders, a sala de teste, os efeitos
sonoros, os construtores e as medições. Os dois primeiros mudaram de pasta 199 ficheiros, com os
seus `.import` e `.uid`, e passaram 415 referências para os caminhos novos; o terceiro passou 40
ficheiros para outra pasta, deu nome novo a um e atualizou 60 referências. Os testes deram os mesmos resultados antes e depois de cada mudança,
teste a teste, nenhuma cena ou recurso ficou a apontar para um caminho antigo, e o projeto importa
sem erros num clone novo.

Para um nível aparecer no New Game, acrescenta-se à lista Levels do Main, no Inspector do `main.tscn`
(Add Element › New LevelEntry, com o título e a cena). A ordem da lista é a dos botões. Um elemento
deixado vazio, ou sem cena, fica fora do menu, com um aviso no Output. Um elemento com In Menu
desligado também fica fora do menu, sem aviso, mas continua na lista, e voltar a ligá-lo devolve-lhe
o botão. É o caso das salas feitas para o desenvolvimento: a sala de teste, o blockout antigo do
nível 1 e a sala de treino. Assim, quem joga não as encontra, e o grupo continua a abri-las com F6.
O `test_main_flow.gd` verifica que as três continuam na lista, fora do menu, e que o nível 1 está nele.
Com um só nível no menu, como agora, o New Game começa-o logo, sem mostrar a lista; com dois ou
mais, mostra a lista.

O nó raiz de cada nível tem o script `scenes/levels/level.gd` (`Level`), com a personagem do nível no campo
Player do Inspector. Quando a personagem morre, este script espera 0,7 s, para que a morte se veja,
escurece o ecrã até ao preto nos últimos 0,3 s e recomeça o nível: no jogo, o Main troca-o por uma cópia nova da
mesma cena; aberto com F6, o nível recarrega-se a si próprio. Uma cópia nova repõe a personagem, os
demónios e a câmara como no início, sem que cada sistema precise de código para se repor. Um nível
sem este script não recomeça. Nas silvas, a espera começa depois do congelamento de 0,1 s.

Passados 0,15 s, o salto encurta a espera: o ecrã escurece logo, em 0,3 s, pelo que a troca mais
cedo continua aos 0,45 s. O preto é puro, sem o tom do nível. O escurecer cresce com o quadrado do
tempo (Fade Ease = 2): começa ténue, enquanto a morte ainda se vê, e fecha com firmeza. A troca faz-se com o ecrã
já escuro, porque recomeçar o nível 1 custa cerca de 0,5 s: 41 ms a instanciar, 43 ms a juntar à
árvore e um frame de cerca de 410 ms a seguir, a maior parte nos tiles (5 rondas,
`tests/measures/measure_restart.gd`). A cópia nova abre com o ecrã escuro e clareia em 0,35 s, ao contrário do
escurecer: quase tudo de uma vez e o resto devagar. A personagem joga-se desde o primeiro frame, pelo
que o clarear não atrasa o regresso ao jogo. Avança no máximo 0,05 s por frame, para que esse primeiro frame longo não salte o clarear. Os
tempos estão no Inspector do nível (Restart Delay, Skip After) e em
`scenes/levels/death_iris_stats.tres` (o escurecer). Fica no código, desligada por omissão (Iris),
uma íris que fecha sobre o corpo e abre sobre a personagem. Testes: `test_level_restart.gd` e
`test_death_iris.gd`.

Na primeira abertura, o Godot gera a pasta `Projeto/.godot/` com a cache de importação. Esta pasta
não é versionada e pode ser apagada sem perda de trabalho.

### Testes e medidas

Os scripts de `Projeto/tests/` correm a partir da raiz do repositório e, exceto os lançadores, sem
janela (`godot` designa o executável do Godot 4.7). Os testes terminam com o código 0 quando passam e 1 quando falham:

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_height.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_air_control.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_movement_stats.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_coyote_time.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_buffer.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wall_slide.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wall_jump.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ledge_assist.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_signals.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_debug_overlay.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lighting_debug_page.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_debug_view.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_game_camera.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_window.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_look_ahead.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_vertical.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_landed_signal.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_zones.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_input.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_keeps_player_on_screen.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_shake.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_controller_rumble.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_rumble_moments.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_warning.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_reveal_rule.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_sight_reveal.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_main_flow.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_pause.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_phase_exit.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lethal_spikes.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_snag.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lethal_spikes_art.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_bramble_motion.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_bramble_death.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_bramble_pull.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_bramble_cut.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_death_iris.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gate.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_cutscene.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_talk_framing.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_phase2_save_entry.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_fires_seated.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_menu_music_fade.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus_appears_in_the_open.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_collapsing_platform.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_phase_2.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_phase_2_route.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_route.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_big_dog.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_biggest_dog.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_phase3.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_phase3_route.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_escape_loop.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_settings.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_options.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_menus.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_input_profiles.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_controls.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_input_map.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_background_layer.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_soul_points.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_target.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_jump.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_path.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_mark.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_sounds.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ambience_layer.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ambience_bed.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ambience_ducking.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wind_embers.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_sound_emitter.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_rising_embers.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_hit_boxes.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_knockback.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_stacked_bodies.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dog_back_bite.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_grab_rules.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_grab_escape.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_block.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_sinking_drawing.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level_restart.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_save_game.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_save_slots.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_save_slots_menu.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_moral_record.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_run_record.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_deaths_log.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level_run_stats.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dialogue_skip.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_death_offer_pacer.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus_deaths.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_velvet_walk.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_asmodeus.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_moral_dialogue.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gym_hint.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gym_stations.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gym.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gym_dogs.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_activity_tracker.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_activity.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_parallax_activity.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_resources_load.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_soul_hud.gd
```

O `test_input_profiles.gd` escreve seis ERROR, das tentativas de atribuir teclas inválidas, todos
esperados. O `test_soul_points.gd` escreve quatro ERROR, das quantidades de dano e de cura
inválidas, também esperados. O `test_moral_record.gd` escreve seis WARNING, de uma tentação
desconhecida (aceite e consultada), de um tom desconhecido e de três tempos de escuta inválidos,
igualmente esperados. O `test_run_record.gd` escreve três WARNING, de mortes sem nível, sem zona e
na fase 0, também esperados. O `test_save_game.gd`, o `test_save_slots.gd` e o
`test_save_slots_menu.gd` criam de propósito gravações danificadas, de uma versão futura e com
campos do tipo errado: cada leitura de um ficheiro danificado dá um ERROR de leitura do Godot, e
cada leitura de uma gravação que o jogo não pode usar dá um WARNING. O `test_save_slots.gd`
escreve ainda dois ERROR, de pedir os slots 0 e 4, que não existem.

Todos os scripts de testes e de medidas estendem `tests/support/base_test.gd`, diretamente ou
através de outro ficheiro de suporte. Antes de o autoload `Settings` estar pronto, esse ficheiro
diz-lhe para guardar as opções só em memória, a partir dos valores predefinidos, sem ler nem
escrever o ficheiro de opções do jogador. Assim, os testes dão o mesmo resultado em qualquer
computador, quaisquer que sejam as opções e os controlos escolhidos nele, e nunca alteram as opções
do jogador.

Os testes da personagem estendem `tests/support/player_test.gd`, que reúne a preparação comum:
plataformas, uma personagem com uma cópia própria dos valores do `.tres`, um `PlayerInput` de
substituição que a conduz sem teclas (`tests/support/stand_in_input.gd`), as esperas (pelo chão,
por uma parede, por uma condição ou por um número de passos) e a escrita dos resultados. Esse
ficheiro não é um teste e não se corre sozinho.

Os testes dos menus estendem `tests/support/menu_test.gd`, que cria a cena principal e carrega em
teclas, botões do comando e botões do rato como o jogador, e reúne o acesso aos nós dos menus, ao
foco e à personagem do nível. Usam um ficheiro de opções próprio e terminam com duas verificações:
o botão Quit não foi carregado e o ficheiro de opções do jogador ficou igual (texto e data de
gravação). Um teste que termine antes dessas verificações, por exemplo porque o jogo fechou por si
em vez de usar o fecho substituto do teste, sai com código 1. Sem esta guarda, o Godot sairia com
código 0 e o teste passaria sem ter verificado nada. O caso do ficheiro estragado do `test_settings.gd` escreve um ERROR e um WARNING, ambos
esperados.

O `measure_movement.gd` não verifica resultados: imprime as medidas da secção "Medidas para o
desenho de níveis", com os valores que estiverem no `.tres`. As medidas junto das bordas correm a
partir de 10 pontos de partida, 1 px entre cada um, que cobrem um passo de física à velocidade
máxima, e imprimem o menor e o maior valor.

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_movement.gd
```

O `measure_crucifix_repel.gd` também não verifica resultados: mede quanto custa, num passo de
física, a lista do que está dentro do raio do crucifixo, com 10, 50 e 200 demónios de substituição,
em chamadas seguidas e no pior caso, e compara esse custo com o limite de 0,05 ms. Com cada número
de demónios, mede também o que somaria comparar essa lista com a do passo anterior, a forma de dizer
`struck` que ficou de fora. Com o crucifixo erguido, mede ainda o seu `_process`, antes do aviso e
durante ele. Os números e as decisões estão em "Crucifixo: componentes e modificadores de movimento".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_crucifix_repel.gd
```

O `measure_soul_points.gd` também não verifica resultados: aplica um golpe que deixa a personagem
com 20 SP e mede, com os valores do `soul_points_stats.tres` e com quatro regenerações de
comparação, o tempo até sair do SP baixo e até encher, e os SP recuperados nos 3 s a seguir à
pausa. Imprime também o que o crucifixo cura durante a pausa. Os números citados em "SP" vêm daqui.

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_soul_points.gd
```

O `measure_demon.gd` também não verifica resultados: mede quanto acrescentam a cada passo de física
10, 50 e 200 demónios a perseguir a personagem, em média e no pior passo, e compara o custo de 50 com
os limites de 1,5 ms em média e 2 ms no pior passo. Mede ainda 50 em ronda, 50 fora de alcance e 50
com o salto ligado, a subir um bloco ou ao pé de um bloco alto demais. Cada parte começa com uma personagem nova, porque
os demónios lhe gastam o SP e, sem um nível que recomece, uma personagem morta num agarrão ficava
presa até ao fim. Os números e a decisão estão em "Demónio: estados,
dados e famílias de personagens".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_demon.gd
```

O `measure_level1.gd` também não verifica resultados: em cinco pontos do percurso do nível 1, mede
quanto custa cada frame com o `ActivityTracker` desligado e ligado, e com o processamento de todos
os cães e desenhos com paralaxe desligado, o mínimo que custariam. Em cada ponto, o rastreador é
medido primeiro desligado num e primeiro ligado no seguinte, para que nenhum dos dois seja sempre
o primeiro. Os números e a decisão estão em "Atividade fora do ecrã".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_level1.gd
```

O `measure_camera_shake.gd` também não verifica resultados: mede quanto custa, num frame desenhado,
o nó que faz tremer o ecrã, sem tremor e com o trauma no máximo, em 100 000 chamadas seguidas. Os
números estão em "Câmara".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_camera_shake.gd
```

O `measure_camera_space.gd` também não verifica resultados: no nível 1, mede quanto do ecrã cada forma
de enquadrar da câmara enche com rocha lisa e a que distância do centro deixa a personagem, e quanto
demora a primeira troca para cada forma. Compara ainda um ecrã de zoom fixo com vários zooms e
posições da personagem. Demora cerca de 4 minutos. Os números estão em "Câmara".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_camera_space.gd
```

O `measure_controller_rumble.gd` também não verifica resultados: mede quanto custa o nó que faz
vibrar o comando num frame desenhado com três impulsos a descer e duas vibrações contínuas a pulsar,
o pior caso, em que pede ao comando em todos os frames; num evento de input; e num impulso iniciado e
parado. Cada medida faz 100 000 chamadas seguidas. Os números estão em "Câmara".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_controller_rumble.gd
```

O `measure_sight_reveal.gd` também não verifica resultados: mede quanto acrescentam os componentes da
linha de vista no nível 1, com a personagem no início, e sem câmara, com elementos escondidos atrás
de uma parede, o pior caso, e com cães à vista, comparando a mesma sala com os componentes ligados e
desligados. Os números estão em "Linha de vista:
um componente por objeto".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_sight_reveal.gd
```

O `measure_brambles.gd` e o `measure_restart.gd` correm com janela, porque sem ela nada se desenha,
e também não verificam resultados. O primeiro mede o tempo de frame no nível 1, com a câmara na
maior faixa de silvas, paradas e a mexer, e o trabalho das faixas num frame dos efeitos; o segundo
mede o custo de recomeçar o nível 1, em 5 rondas. Os números estão em "Portões, picos letais e
plataformas que desabam" e na descrição do `Level`.

```
godot --path Projeto --script res://tests/measures/measure_brambles.gd
godot --path Projeto --script res://tests/measures/measure_restart.gd
```

O `measure_joypads.gd` precisa de um comando ligado e também corre sem `--headless`, porque
sem janela o Godot não lê comandos. Lista os comandos que o motor vê, faz vibrar cada motor e, durante
20 s, escreve cada ação e cada botão premidos, com a janela em foco. Sai com o código 1 se não houver
comando.

```
godot --path Projeto --script res://tests/measures/measure_joypads.gd
```

### A personagem por dentro

A cena é `scenes/characters/player/player.tscn`, com o script `scenes/characters/player/player.gd`: um `CharacterBody2D` com uma
caixa de colisão de 48 × 96 px e a origem nos pés, pelo que, num nível, a origem fica na linha do
chão. Está na camada `player` e colide com `world`, `one_way_platform` e `enemy`. Os valores vêm de um
recurso `PlayerMovementStats` (`scenes/characters/player/player_movement_stats.gd`), guardado em
`scenes/characters/player/player_movement_stats.tres`.

O desenho é um `Sprite2D` com uma imagem provisória, feita a partir do desenho de conceito
(`assets/sprites/player/player_concept.png`): uma célula de 192 × 192 px, com os pés na linha
y = 184, ao centro, e o corpo do tamanho da caixa de colisão (43 × 96 px). O sprite fica em (0, −88),
o que põe os pés na origem. As animações vão substituir esta imagem, com a mesma célula e a mesma
linha dos pés.

A personagem não lê o teclado diretamente. Um nó filho, `PlayerInput` (`scenes/characters/player/player_input.gd`), é
o único que lê as ações da personagem no Input Map, e responde em cada passo de física a cinco
perguntas: a direção da corrida e, para os botões de saltar e do crucifixo, se acabaram de ser
premidos e se continuam premidos. A personagem recebe
este nó pelo Inspector, no campo Input. Um controlador automático, uma cena animada ou um teste
controlam a personagem colocando nesse campo outro nó que estenda `PlayerInput`, sem alterar o
movimento. É o primeiro passo do padrão Component descrito por Nystrom (2014, capítulo
"Component"), que separa a entrada do resto do objeto. Quando existirem, a pausa, o diálogo e a
assistência de salto completo poderão atuar nesse único ponto. O `test_player_input.gd` verifica que, com um desses nós, a personagem corre,
salta, completa o salto e se encosta à parede sem nenhuma tecla premida, e que as teclas deixam de
ter efeito.

A lógica organiza-se numa máquina de estados com três estados, definida por um `enum` no
`player.gd`: no chão (`ON_FLOOR`), no ar (`IN_AIR`) e na parede (`ON_WALL`). Cada estado tem a sua
função de física, e o estado só muda em `_update_state()`, no início de cada passo de física, a
partir do resultado do último `move_and_slide()`. O chão tem prioridade. Fora do chão, tocar numa
parede do nível põe a personagem no estado da parede, a menos que o jogador empurre para o lado
oposto; no lado de um demónio, é preciso empurrar. O estado termina quando a personagem deixa de
tocar na parede, quando o jogador empurra para fora ou quando aterra. Uma parede do nível é um
corpo ou um tile fora das Knock Off Layers. A camada lê-se no servidor de física, que serve para
os dois, porque um `TileMapLayer` não é um `CollisionObject2D`. Preferiu-se o `enum` a um nó por
estado (padrão State) porque os três estados partilham a gravidade, a corrida e os contadores.
Segue-se a ordem proposta por Nystrom (2014, capítulo "State"): primeiro o `enum`, e o padrão State quando um estado
passar a ter dados que só nele fazem sentido, como agarrar bordas. As animações vão depender do
estado e da velocidade; as que tocam uma só vez (início do salto, aterragem, salto da parede) vão
ser disparadas por sinais. Os sinais do salto já existem; o da aterragem será acrescentado com o
primeiro sistema que precise dele.

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
- A ajuda nos degraus corre logo antes do `move_and_slide()`. Se o passo seguinte, no sentido em que
  a personagem se move ou, parada de lado, no da parede em que toca, bate numa parede do nível, o
  `test_move()` procura, de píxel em píxel até ao Ledge Assist Height, a menor subida a partir da
  qual esse passo fica livre. A personagem sobe essa altura, e mais 1 px para cima da borda, para
  pousar mesmo sem velocidade de lado; sem esse píxel, ficava a pairar junto à face, subida em
  cada passo. Deixa de cair, e a tolerância de parede esvazia-se, como ao
  aterrar, para que a tecla de saltar não dê um salto da parede para trás. Um teto não precisa de
  verificação própria: a personagem é mais alta do que qualquer subida, e o `test_move()`
  empurra-a para fora do teto, para baixo, onde a parede ainda trava o passo. O
  `test_ledge_assist.gd` verifica-o.
- A personagem emite um sinal em cada salto: `jumped` no salto do chão, incluindo os que usam as
  tolerâncias, e `wall_jumped` no salto da parede, que não emite o primeiro. Ambos enviam dois
  valores: os passos de física decorridos desde que a personagem deixou o chão ou a parede (0 se
  ainda lá estava) e os passos em que o pedido de salto esteve guardado (0 se foi feito no próprio
  passo do salto). Uma função ligada a estes sinais tem de receber os dois valores, ou ser ligada
  com `.unbind(2)`; caso contrário, o Godot regista um erro e não a chama. O estado atual lê-se
  com `get_state()`, que não permite alterá-lo. O `test_jump_signals.gd` verifica os sinais nos
  limites das duas tolerâncias.
- A personagem emite `landed`, sem valores, cada vez que volta ao chão depois do ar ou de uma
  parede. O sinal surge quando o estado passa a `ON_FLOOR`, no passo de física a seguir ao do
  contacto, pelo que quem o recebe já encontra esse estado. A câmara usa-o para reenquadrar; a
  altura da queda será acrescentada quando existir dano de queda. O `test_landed_signal.gd`
  verifica-o depois de uma queda, de um salto, de uma borda e de uma parede.

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

#### Physics interpolation

A física do jogo corre 60 vezes por segundo, e o ecrã é desenhado à frequência do monitor, que pode
ser superior (120 Hz ou 144 Hz, por exemplo). Sem compensação, um monitor de 144 Hz mostra frames em
que nada se deslocou, e o movimento parece aos solavancos, sobretudo quando a câmara segue a
personagem. Com a *physics interpolation* ativa (Project Settings ▸ Physics ▸ Common), cada objeto é
desenhado numa posição intermédia entre os dois últimos passos de física, e o movimento fica contínuo
a qualquer frequência. Em troca, a imagem fica atrasada até um passo de física (16,7 ms). A física em
si não muda: os testes e as medidas do movimento dão os mesmos resultados com e sem interpolação.

Desta opção resultam duas regras:

- Um nó que se desloca deve fazê-lo em `_physics_process()`. Um nó deslocado em `_process()` treme,
  a menos que a interpolação seja desligada nesse nó (`physics_interpolation_mode`).
- Um teletransporte, como o regresso da personagem a um ponto de partida, termina com
  `reset_physics_interpolation()`. Sem isso, o objeto é desenhado a atravessar o espaço entre as duas
  posições.

A `Camera2D` passa a ser processada no passo de física, e o Godot emite um aviso se ela estiver
configurada para o modo Idle. Pela mesma razão, a suavização própria da `Camera2D` (Position
Smoothing) não é usada: com a interpolação ativa, é aplicada mais do que uma vez por passo de física,
e o mesmo valor deixava a câmara a 81 px da personagem a correr a 720 px/s, a velocidade da altura,
contra 144 px sem interpolação. A
câmara do jogo faz a sua própria suavização, uma vez por passo.

#### Input: ações nomeadas com teclas físicas

Nenhum script lê teclas diretamente. Todo o input passa pelo Input Map, com `Input.get_axis()` e
`Input.is_action_just_pressed()`, para que os controlos possam ser remapeados sem alterar o código
de gameplay. As teclas estão registadas como físicas (`physical_keycode`): contam pela posição no
teclado, e não pela letra impressa, pelo que o WASD se mantém num teclado AZERTY ou QWERTZ.

| Ação | Teclado | Comando |
|---|---|---|
| `move_left` / `move_right` | A / D, setas | stick esquerdo (eixo 0), D-pad |
| `move_up` / `move_down` | W / S, setas | stick esquerdo (eixo 1), D-pad |
| `jump` | Espaço | A / Cross |
| `interact` | E | X / Square |
| `crucifix` | Shift | RT / R2 (eixo 5) |
| `pause` | Escape | Start |
| `debug_god_mode` / `debug_noclip` | F1 / F2 | — |
| `toggle_debug_overlay` | F3 | — |
| `debug_damage` | F4 | — |
| `debug_accept_offer` / `debug_refuse_offer` | F7 / F8 | — |
| `debug_reset_run` | F9 | — |
| `debug_camera_next` | F10 | — |
| `debug_phase_1` / `debug_phase_2` / `debug_phase_3` | 1 / 2 / 3 (só na página dos números do overlay) | — |
| `ui_accept` | Enter, Espaço | A / Cross |
| `ui_cancel` | Escape | B / Circle |
| `menu_previous_tab` / `menu_next_tab` | — | LB / L1, RB / R1 (separadores das opções) |

O `ui_accept` e o `ui_cancel` são ações que o Godot já traz para os menus; acrescentou-se-lhes o A e o
B do comando, que não tinham.

O teclado e o comando foram revistos em conjunto (ADR 0063). O grupo experimentou o crucifixo no
botão esquerdo do rato e ninguém se adaptou, pelo que o perfil predefinido passou a usar só o
teclado: o Shift, premido com o dedo mínimo, ergue o crucifixo sem tirar os outros dedos do WASD e do
Espaço, e o E, ao lado, interage. O perfil mantém as setas para andar, pelo que também se joga com
as duas mãos. No comando, o interagir passou do clique do stick direito, um stick que o jogo não usa,
para o X, ao lado do A, e o B serve, por agora, só para voltar nos menus. O D-pad também anda, para
quem prefere o movimento digital ao stick. No perfil predefinido, nenhuma tecla, botão ou direção
serve duas ações de jogo; o Espaço e o A também confirmam nos menus, de propósito.

Os poderes dos upgrades vão usar o botão do crucifixo: o crucifixo perde-se no primeiro upgrade
aceite, pelo que os dois nunca coexistem, e o Shift e o RT (o Q, no perfil das setas) passam a usar
o poder ativo. Trocar de poder fica no LB e no RB e, no perfil WASD, no Q e no R; o Y, o B e o LT
ficam livres para a espada do nível 5. Estas ações entram no Input Map quando o primeiro upgrade
for implementado.

Limitações conhecidas. No Windows, cinco toques seguidos no Shift abrem o aviso das Teclas Fixas
(Sticky Keys); quem se incomodar pode mudar o crucifixo para outra tecla no perfil Custom. As teclas
desenhadas no tutorial ainda só mostram o teclado, pelo que quem joga com o comando não vê nelas o
botão de cada ação. O comando ainda não se remapeia (issue #249), e o crucifixo só se ergue
mantendo o botão premido, sem opção de alternar (issue #250).

O `test_input_map.gd` verifica que cada ação de jogo do perfil predefinido tem exatamente as teclas,
os botões e as direções desta tabela, nem mais nem menos, que não usa o rato, que nenhuma entrada
serve duas ações de jogo e que os menus navegam com o D-pad e com o stick. Verifica também que,
com o Shift premido, o A continua a andar e o Espaço continua a chegar ao salto. O
`tests/measures/measure_joypads.gd` (ver "Testes e medidas") escreve cada ação e cada botão
premidos num comando ligado, para confirmar a tabela num comando real.

As teclas desta tabela são as do perfil de controlos predefinido. O jogador pode escolher outro
perfil nas opções, e o `Settings` substitui, durante o jogo, as teclas e os botões do rato das ações
de jogo (ver "Controlos: perfis e remapeamento").

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
| | | 11 | `repellable` |

A separação entre *hitbox* (o que causa dano) e *hurtbox* (o que recebe dano) permite que um ataque
atravesse um inimigo sem o empurrar e, se for desejado, que os inimigos se atinjam entre si. Hoje, a
`Hitbox` dos demónios está em `enemy_hitbox` e não procura nada; a `Hurtbox` da personagem está em
`player_hurtbox` e procura apenas em `enemy_hitbox`. Só quem recebe o golpe procura, pelo que cada
golpe é detetado uma vez, de um só lado. A mordida nas costas dos cães não muda isto: o
`DemonBackBite` procura em `player` o corpo da personagem, para saber quando ela está de pé no cão,
mas o golpe continua a ser detetado só pela `Hurtbox` (ADR 0056).

A camada `camera_bounds` é a das zonas de câmara (`CameraZone`): retângulos que limitam o que o ecrã
mostra enquanto a personagem está dentro deles. As zonas não detetam colisões; a câmara lê-lhes a
geometria, e a camada serve para as identificar e desenhar no editor.

A camada `repellable` é a da cena `scenes/characters/components/repellable.tscn`, que se coloca em tudo o que o
crucifixo afasta. A camada está definida na cena, no Inspector, e não no código. O crucifixo procura
apenas nessa camada, pelo que um demónio ou uma alma só é afastado se tiver o componente.

A camada `enemy` é a do corpo dos demónios, que colide com `world`, `one_way_platform` e `player`.
Os corpos dos demónios atravessam-se uns aos outros, para que não tremam nem se bloqueiem; parados
ou fora da caça, é a separação da matilha que os mantém afastados, e na caça passam uns pelos
outros (ver "Demónios"). A personagem e os demónios não se
atravessam: param encostados, e nenhum dos dois fica de pé em cima do outro (ver "Pancada e
agarrão"); só presos dos dois lados se atravessam, durante uma fração de segundo. Um demónio que caia de uma borda em cima da personagem, ou dois
demónios dos dois lados, podem encurralá-la; é intencional, porque encostar a um demónio é ficar ao
alcance da mordida, e vigia-se nos playtests.

#### Crucifixo: componentes e modificadores de movimento

O crucifixo foi construído para não criar dependências entre sistemas, com padrões comuns na
indústria:

- **Componente** (Nystrom, 2014, capítulo "Component"). O crucifixo é uma cena própria
  (`scenes/characters/crucifix/crucifix.tscn`), filha da personagem. Lê o botão através do mesmo `PlayerInput` da
  personagem, pelo que um controlador automático, uma cena animada ou um teste também o controlam.
- **Modificadores de movimento.** A personagem não sabe que o crucifixo existe. Aceita
  modificadores (`MovementModifier`), cada um com uma fração da velocidade, uma fração da altura do
  salto e a indicação de que impede o salto, guardados pelo nome de quem os colocou. As frações
  multiplicam-se entre si, e basta um modificador para impedir o salto. O crucifixo coloca o seu ao
  ser erguido e retira-o ao baixar. O nível da preguiça poderá abrandar a personagem da mesma forma,
  e os dois efeitos acumulam-se. Preferiu-se esta solução a uma ligação direta da personagem ao
  crucifixo, que obrigaria a alterar a personagem a cada novo efeito. Um modificador é um
  `Resource`: avisa quando um dos seus valores muda (sinal `changed`), e a personagem, que o escuta
  enquanto o tem, aplica a mudança de imediato. Também se pode criar no Inspector e gravar, por
  exemplo para uma zona de um nível que abranda a personagem. A fração da altura do salto aplica-se
  multiplicando a velocidade de partida pela sua raiz quadrada, porque, com a mesma gravidade, a
  altura é proporcional ao quadrado dessa velocidade.
- **Ativação ao premir, com tolerância.** O crucifixo ergue-se no passo em que o botão é premido
  (`is_crucifix_just_pressed`) e mantém-se enquanto continua premido (`is_crucifix_held`), como é
  habitual nas habilidades. Isto resolve, sem estado extra, os botões que já vinham premidos do
  bloqueio, do menu principal ou da pausa: nenhum deles é um toque novo. Para um toque dado um pouco
  cedo não se perder, fica guardado durante o Raise Buffer Time, à semelhança da tolerância do
  salto.
- **Máquina de estados com tempos em passos de física.** O crucifixo tem três fases: pronto,
  erguido e bloqueado depois de esvaziar (`READY`, `RAISED`, `COOLDOWN`). A carga, o bloqueio e a
  tolerância contam-se em passos de física inteiros, como as tolerâncias do salto, para que os
  testes os verifiquem ao passo exato. A carga guarda-se em unidades inteiras: cada passo erguido
  gasta tantas quantos os passos do Cooldown Time, e cada passo em baixo devolve tantas quantos os
  do Max Use Time, para a carga encher de vazia a cheia exatamente no Cooldown Time, sem
  arredondamentos. Os sinais `cooldown_started` e `cooldown_finished`, a carga (`get_charge()`) e o
  tempo restante do bloqueio servem o HUD.
- **Componente `Repellable`** (`scenes/characters/components/repellable.tscn`), à semelhança dos *hitboxes* e
  *hurtboxes*. É uma `Area2D` que se coloca nos demónios e nas almas perdidas, com a camada
  `repellable` definida na cena. O crucifixo empurra apenas o que tem este componente e não conhece
  os scripts dos demónios nem das almas; estes recebem o sinal `repelled`, para reagir com uma
  animação ou largar uma alma agarrada. Sem mais nada, o empurrão segue a linha do crucifixo à
  posição do que empurra, que num demónio fica nos pés. A opção Along Floor, ligada nos demónios,
  torna-o horizontal: o crucifixo está 60 px acima dos pés da personagem, e, para um demónio no mesmo
  chão, aquela linha aponta para o chão. Como o movimento para no primeiro contacto, um demónio a
  100 px da personagem só se afastava 16 px em 2 s, e um demónio por baixo dela não se movia
  (medido). A opção fica desligada por omissão, para as almas, que voam. Nos demónios, o primeiro
  `repelled` desencadeia também o arremesso (ver "Afastamento pelo crucifixo").
- **Valores afináveis com o jogo a correr.** O `CrucifixStats` avisa quando o raio ou o
  abrandamento mudam, e o crucifixo aplica-os de imediato: o raio à área de afastamento e ao alcance
  da luz, que assim mostra sempre a área onde o crucifixo atua, e o abrandamento ao seu
  modificador.

Com o resto do jogo, o crucifixo comunica por sinais (`raised`, `lowered`, `ran_out`, `refused`,
`cooldown_started`, `cooldown_finished`, `lost`, `healed` e `struck`), que o HUD e o som poderão
escutar e que os SP e a vibração já escutam (ver "SP: componente, dados e ligação ao crucifixo").
Perdido, emite `lost` e sai do jogo (`queue_free`); o HUD retira o ícone ao receber esse sinal. A
exceção é o afastamento: o crucifixo empurra os demónios e as almas chamando o componente
`Repellable` de cada um (ver acima), sem conhecer os seus scripts.

O aviso de que o crucifixo vai baixar também vive no crucifixo. O `get_warning_progress()` diz
quanto do aviso já passou, de 0 a 1, e o `get_warning_pulse()` diz que parte do brilho a luz tem
nesse momento. A luz e o som do crucifixo erguido seguem o segundo, e a vibração lê o primeiro.
Assim, todos seguem o mesmo relógio, e um valor novo de Warning Time chega a todos. O volume do som
segue a parte do brilho que a luz tem, o que o baixa cerca de 8 dB na descida mais funda; só o volume
muda, porque mexer no tom soaria a avaria e chocaria com a música. O `_process` do
crucifixo só corre com ele erguido e só muda a energia da luz; ao baixar, a luz volta ao brilho da
cena. Custa cerca de 0,5 a 0,7 µs por frame. A fase da pulsação conta-se a partir do fim do uso, para
a descida mais funda coincidir com o instante em que o crucifixo baixa: contada a partir do início,
a luz estaria no brilho todo ao apagar-se.

O `struck` vem do sinal `area_entered` da área de afastamento, que o motor de física já calcula, e
diz-se uma vez por passo de física, por muitos que entrem nesse passo. O que já está no raio quando
o crucifixo se ergue conta nesse momento, e o que entra com ele em baixo não conta. Só conta o que o
crucifixo empurra, um `Repellable` com Target: um elemento que ele só alcance, sem o empurrar, não
conta. Ficou de fora comparar, em cada passo, a lista do que está no raio com a do passo anterior.
Essa comparação soma cerca de 4 µs por passo com 10 demónios no raio, 35 µs com 50 e 390 µs com 200:
com quatro vezes mais demónios, custa cerca de onze vezes mais, perto do quadrado. Com o sinal, um
passo em que nada entra não custa nada a mais. Os números deste parágrafo e do anterior vêm do
`measure_crucifix_repel.gd` (três execuções, 2026-11-14).

Com a personagem é diferente. O crucifixo recebe-a no Inspector (propriedade Player), lê o botão
através do `PlayerInput` dela, pergunta-lhe se está no chão e coloca e retira o seu modificador.
São chamadas de um nó filho para o pai, uma exceção à convenção "call down, signal up" (ver
"Convenções de código"). A razão é que o crucifixo precisa, em cada passo de física, do botão e do
estado da personagem, e um sinal serve para anunciar que algo aconteceu, não para pedir dados a cada
passo. Com essa referência já necessária, colocar o modificador através de um sinal genérico ligado
na cena seria um segundo caminho para a mesma ligação. A alternativa de a personagem escutar os
sinais do crucifixo e aplicar ela própria o abrandamento obrigá-la-ia a conhecer o crucifixo e a ser
alterada a cada novo efeito, que é o que os modificadores evitam. A ligação tem um só sentido, do
crucifixo para a personagem, cujo código não usa o crucifixo, e é atribuída na cena, sem caminhos
entre nós escritos no código.

Enquanto está erguido, o crucifixo pede em cada passo de física a lista do que está dentro do raio,
e o motor cria essa lista de novo a cada pedido. Em código que corre em cada passo, é boa prática não
criar listas novas, porque criá-las e libertá-las tem um custo; a alternativa seria o crucifixo
manter a sua própria lista, atualizada quando um demónio entra ou sai do raio. Antes de decidir,
fixou-se um limite de 0,05 ms por passo (50 µs, ou milionésimas de segundo), 0,3 % de um passo de
16,6 ms, e mediu-se o custo com o `measure_crucifix_repel.gd` (2026-10-19, três execuções). Os
valores incluem criar e libertar a lista:

| Demónios no raio | Muitas chamadas seguidas | Uma chamada por passo, no pior caso |
|---|---|---|
| 10 | 0,4 a 0,6 µs | 11 a 14 µs |
| 50 | 1,2 a 1,7 µs | 16 a 19 µs |
| 200 | 4,8 a 5,3 µs | 30 a 35 µs |

Chamadas seguidas encontram os dados na memória rápida do processador (cache). No jogo, outros
sistemas ocupam essa memória entre dois passos, e o pior caso, em que a memória rápida é ocupada
por completo antes de cada chamada, mede esse efeito. Mesmo assim, com 50 demónios o custo fica
cerca de 3 vezes abaixo do limite, e com 200 continua abaixo. Os valores foram medidos com o
executável do editor do Godot, num só computador. Em GDScript, a lista é libertada assim que deixa
de ser usada, sem as pausas de recolha de memória de outras linguagens. Manteve-se, por isso, a
solução mais simples; se um nível juntar muitos mais demónios num só raio, a medida volta a correr.

O `test_crucifix.gd` verifica os modificadores (a combinação, uma mudança com o modificador
colocado, a fração da altura do salto e a da velocidade no salto da parede), o abrandamento, o
bloqueio do salto, a tolerância antes de aterrar e antes do fim da espera, o toque dado demasiado
cedo, a parede, a saída do chão, a duração máxima, a carga gasta e recuperada ao passo exato, o
bloqueio ao esvaziar, o tempo mínimo em baixo entre toques rápidos, a pausa, a perda, a cura, o
afastamento, a camada da cena `Repellable` e a afinação com o jogo a correr. Usa um demónio de
substituição, que flutua à altura do crucifixo; o afastamento de um demónio no chão verifica-se no
`test_demon.gd`, com o crucifixo da personagem. O `test_crucifix_menus.gd` usa a cena principal,
com o crucifixo no botão esquerdo do rato pelo perfil Custom: com o botão premido durante a pausa
e mantido ao retomar com Esc, com um clique no Resume e com o botão premido desde o menu principal,
o crucifixo não se ergue até o botão ser largado e premido de novo no jogo. O
`test_crucifix_warning.gd` verifica o aviso: a luz com o brilho todo antes
dele e a pulsar entre os limites durante ele, mais funda no fim, a mais funda no último instante, e
sem passar a frequência; de volta ao brilho todo ao baixar, também quando o botão é largado a meio
do aviso; o volume do som a seguir a luz e de volta ao normal ao baixar; o aviso a 0 no instante
em que baixa; e o `_process` do crucifixo e dos seus sons só com ele erguido. Verifica
também que os valores do jogo pulsam três vezes por segundo ou menos.

#### SP: componente, dados e ligação ao crucifixo

Os SP são um nó-componente, `SoulPoints` (`scenes/characters/player/soul_points.gd`), filho da personagem, com os
valores num `Resource`, `SoulPointsStats`, como o movimento e o crucifixo. A personagem recebe-o no
Inspector (propriedade Soul Points), para que tudo o que a fere ou cura o encontre através dela.
Separado da personagem, o componente testa-se sem ela e não acrescenta mais um sistema ao script da
personagem, que já reúne o movimento. Um componente de vida genérico, partilhado com os demónios,
ficou de lado: só se justifica quando um segundo sistema precisar dele, e os demónios não têm vida,
porque a personagem não ataca.

- **Sinais.** Num golpe, o componente emite `damaged`, `sp_changed`, `low_changed` e `depleted`, por
  esta ordem; o `low_changed` só quando os SP passam o limiar, num sentido ou no outro, e o
  `depleted` uma única vez. O `depleted` vem por último para que a barra e o som já tenham recebido
  o valor final quando a morte começar. A barra, os sons, os avisos e a morte poderão escutá-los
  sem que o componente conheça nenhum deles. Uma quantidade negativa, infinita ou indefinida
  (NaN) é um erro e não altera nada.
- **Regeneração no passo de física.** A pausa depois do dano e a subida da velocidade contam-se em
  passos de física inteiros, como as tolerâncias do salto, para que os testes as verifiquem ao passo
  exato. A velocidade de cada passo é uma interpolação linear entre a velocidade inicial e a final,
  pela fração já decorrida do tempo de subida; essa conta pertence ao `SoulPointsStats`, e o
  componente apenas conta os passos. Um golpe põe a contagem a zero; a cura não. Com o jogo em
  pausa, a regeneração para com o nível.
- **Valores afináveis com o jogo a correr.** O `SoulPointsStats` avisa quando o máximo ou o limiar
  mudam, e o componente aplica-os de imediato: um máximo mais baixo do que os SP atuais desce-os
  com ele.

O crucifixo cura através de uma ligação na cena da personagem: em `scenes/characters/player/player.tscn`, o sinal
`healed` do crucifixo está ligado ao método `heal` dos SP. Nenhum dos dois scripts conhece o outro;
quem os liga é a cena que os contém. A alternativa seria o crucifixo chamar os SP através da
personagem, como já faz com o modificador, mas essa exceção à convenção "call down, signal up"
justifica-se por o crucifixo ter de pedir dados à personagem em cada passo. A cura é algo que o
crucifixo anuncia, e anunciar é o papel de um sinal.

O `test_soul_points.gd` verifica o componente sem personagem: os limites de 0 e do máximo, os
sinais e a sua ordem, o SP baixo, o fim dos SP, as quantidades inválidas, um máximo diferente só
com dados, a pausa depois do dano, a subida da velocidade, a pausa do jogo e a velocidade que o
overlay mostra. Os casos usam valores próprios, pelo que afinar o `.tres` não os altera. O
`test_crucifix.gd` verifica que um segundo com o crucifixo erguido dá 5 SP à personagem, através da
ligação da cena.

#### Demónio: estados, dados e famílias de personagens

Todos os demónios que perseguem a personagem, em todos os níveis, usam uma só cena,
`scenes/characters/demon/demon.tscn`, com os valores num `Resource`, `DemonStats`, como o movimento, o crucifixo e os
SP. Cada ataque é outro `Resource`, `DemonAttack`, e o `DemonStats` tem a lista dos ataques do
demónio. Os do nível 1 estão em `scenes/characters/demon/lust_demon_stats.tres`, e os do cão grande, iguais exceto no
dano, em `scenes/characters/demon/big_demon_stats.tres`; os demónios de um nível novo são
outro ficheiro com os mesmos campos, outros ataques e outra arte, sem código novo.

As personagens dividem-se pelo que fazem, e não pela história: as que perseguem usam esta cena, e as
que falam sem perseguir (o demónio do tutorial, as almas e os bosses) têm ou terão cenas próprias. O que
as duas famílias partilham são componentes, como o `Repellable`, e não uma classe-mãe. Uma
classe-mãe comum ficaria quase vazia e não serviria uma personagem das duas famílias, como uma alma
que fala e que o crucifixo afasta. Pela mesma razão, o demónio do tutorial, que fala e não persegue,
não é esta cena com a perseguição desligada.

O demónio do tutorial, a Velvet (`scenes/characters/demon/tutorial_demon.tscn`), é um cão que passeia
na sua zona: anda 128 px para cada lado do sítio onde está no nível, a 88 px/s, e descansa 1,5 s em
cada ponta (grupo Walk do Inspector). Enquanto o homem está na Talk Area dela, ou enquanto fala, fica
parada e virada para ele. A Talk Area não acompanha o passeio, para que o sítio onde a conversa começa
não dependa do momento em que o homem chega. O frame da folha segue o chão percorrido, 11 px por
frame, para que as patas não escorreguem a nenhuma velocidade. Ela anda sem colidir, por isso a zona
tem de ser chão plano. A caixa de colisão cobre o tronco (66 × 54 px), sem a cabeça nem a cauda.

- **Um objeto por estado.** Os catorze estados (`IDLE`, `CHASE`, `WARNING`, `LUNGE`, `RETREAT`,
  `GRAB`, `THROWN`, `REPELLED`, `STUNNED`, `RETURN`, `OUT_OF_REACH`, `PATROL`, `ALERT` e `SEARCH`)
  continuam a ser uma
  enumeração no `demon.gd`, que a arte, o som e os testes leem, mas o que o demónio faz em cada um
  está num objeto próprio, uma classe derivada de `DemonState`, em `scenes/characters/demon/states/` (o padrão State).
  Com a ronda e o "fora de alcance", o `demon.gd` chegou às 825 linhas, e sete estados partilhavam
  um mesmo contador de passos, posto a zero à mão antes de cada mudança. Agora, cada estado guarda os
  seus contadores e diz o que prepara ao começar e o que arruma ao sair. O demónio cria os
  objetos uma vez, ao entrar na cena, e muda de estado só por um método, `change_state`, que liga ou
  desliga a `Hitbox` e avisa a arte e o som. Os estados usam o corpo, os sentidos e os ataques do
  demónio pelos métodos cuja documentação começa por "For its states". Os objetos não são nós da
  cena: assim o `demon.tscn` não muda, cada demónio não ganha doze nós (600 com 50 demónios) e os
  valores continuam todos no `DemonStats`. O alerta e a procura, que o desenho do nível 1 pedia,
  entraram assim: dois ficheiros novos, cada um com o seu nome na enumeração e a linha que o cria
  no `demon.gd` (ADR 0035). O alvo e a memória passaram depois para um componente (ver "Alvo e
  memória num componente"); a escolha do ataque, a mordida e a perseguição continuam no
  `demon.gd`. A divisão em objetos não alterou o
  comportamento: os 105 casos do
  `test_demon.gd` passam sem alterações. Também não alterou o custo: com 50 demónios a perseguir, o
  tempo dos scripts por passo foi, em mediana de quatro execuções alternadas, 0,87 ms antes e
  0,86 ms depois.
- **Ataques como dados.** Cada `DemonAttack` guarda o alcance, a diferença de altura, o aviso, as
  distâncias, a antecipação (Lead), a altura e o tempo do salto, a recuperação, a probabilidade e a
  animação. A ordem na lista é a prioridade: com a personagem ao alcance dos dois ataques, o demónio
  usa o primeiro, a mordida. A mordida a correr é o mesmo `Resource` com o Keeps Chasing ligado, e
  não uma subclasse: com dois ataques, um interruptor nos dados chega, e um ataque novo que caiba
  nestes campos não pede código. Ao arrancar, o demónio confirma que a animação de cada ataque
  existe na lista das animações da arte.
- **Probabilidade por segundo.** O Chance Per Second é a probabilidade de o ataque começar em cada
  segundo em que a personagem está ao alcance. Em cada passo de física, de Δt segundos, o demónio
  sorteia com a probabilidade 1 − (1 − p)^Δt, o que dá a mesma probabilidade por segundo a qualquer
  frequência de física. O `test_demon.gd` verifica-o a 60 e a 120 passos por segundo, na fórmula e
  no sorteio do próprio demónio: com uma semente fixa e p = 0,5, o ataque começou em 48 % e em
  49,7 % de 1000 segundos. Com probabilidade 1, todos os demónios saltavam à mesma distância e eram
  fáceis de prever. Cada demónio tem o seu gerador de números aleatórios, com uma semente tirada do
  gerador global, para que demónios colocados no mesmo passo não ataquem juntos.
- **Pontaria.** No início do aviso, o demónio calcula onde a personagem vai estar quando ele
  aterrar. Usa a velocidade dela, que mede pela diferença de posição em cada passo de física, e não
  lendo o script da personagem: assim, uma plataforma que a transporte também conta, e o demónio
  não depende dela. O Lead, de 0 a 1, diz quanto dessa velocidade conta. O tempo até aterrar
  depende da distância do salto (ver o ponto seguinte), e a distância depende de onde ela vai estar
  nesse momento; escrito em u, a raiz quadrada da distância, isto dá uma equação de segundo grau, e
  a raiz positiva dá a distância. O salto fica entre 200 e 420 px, e não acontece se, quando o
  demónio aterrar, ela estiver ao nível dele ou atrás. A pontaria fica fixa até ao fim, como a
  direção. No `test_demon.gd`, com os valores do teste, o salto aterrou a 2,3 px de uma personagem
  parada e a 3,0 px de uma que se afastava a 50 px/s.
- **Alvo e memória num componente.** O que o demónio sabe da personagem que persegue está no
  `DemonTarget` (`scenes/characters/demon/demon_target.gd`): a caixa e a `Hurtbox` dela, a velocidade a que anda, há
  quantos passos não a vê, e onde e quando a viu pela última vez. O componente só guarda e conta; é
  o `demon.gd` que decide desistir, procurar ou atacar. Ao largar a personagem, guarda o último
  sítio onde a viu, que é para onde a procura vai. Não é um nó da cena, pelas razões dos estados.
  Testa-se sozinho, sem cena (`test_demon_target.gd`), e os 112 casos do `test_demon.gd` passam sem
  alterações. Custa cerca de 1,6 µs por demónio e por passo: com 50 a perseguir, o tempo dos
  scripts foi, em mediana de quatro execuções alternadas, 0,91 ms antes e 0,99 ms depois, dentro do
  orçamento (ADR 0037).
- **Sentidos num componente.** O que o demónio percebe da personagem está no `DemonSenses`
  (`scenes/characters/demon/demon_senses.gd`): uma área circular, do raio do Sight Distance, encontra-a, e um raio
  confirma que nenhuma parede está entre os olhos do demónio e o meio dela ou, se esse estiver
  tapado, a cabeça. Com um só ponto, uma personagem numa plataforma ficava escondida pela própria
  plataforma. O componente diz também se o demónio repara nela (à frente, ou atrás até ao Sight
  Behind Share do alcance) e se ele está no ecrã: o retângulo do ecrã sai da transformação da
  câmara, que inclui o zoom das zonas. O `VisibleOnScreenNotifier2D` do Godot ficou de lado
  porque depende do desenho do ecrã, que não existe nos testes sem janela. Sem câmara, como nos
  testes, todo o mundo conta como ecrã. O componente recebe os nós que já existiam por `@export`,
  e por isso a cena não mudou de forma. O demónio só lhe faz perguntas, e o componente nunca o
  move. A cabeça está sempre ligada: só alarga o que o demónio vê, e nenhum dos casos de teste
  anteriores mudou de resultado. O alcance para trás, o ecrã e o regresso ligam-se por valores no
  `DemonStats` que, por defeito, mantêm o comportamento antigo (ADR 0032). A cabeça conta só com a
  personagem dentro da área: numa perseguição para lá do Sight Distance, conta só o meio. Um segundo raio, curto e à frente dos
  pés, procura o chão: deteta as bordas durante a perseguição e, antes do aviso, percorre o caminho
  do salto de 24 em 24 px, meia largura da personagem, para que nenhum buraco escape. Percorre-o até
  ao ponto mais distante onde o salto pode aterrar, a distância pedida mais meio passo de física
  (ver o ponto seguinte). Quando a procura parava na distância pedida, um demónio com um salto
  rápido (0,05 s até ao ponto mais alto) ia parar a 452,3 px, além do fim de um chão de 424 px, e
  caía (medido no `test_demon.gd`, antes da correção).
- **Salto calculado a partir do desenho.** O ficheiro de dados indica a altura e a distância do
  salto mais longo e o tempo até ao ponto mais alto. O código calcula a partir deles a velocidade de
  partida e uma gravidade própria do salto, o mesmo método do salto da personagem (Pittman, 2016).
  Com a gravidade do projeto, a altura fixava a duração: o primeiro salto, de 40 px, durava 35
  passos (0,58 s), lento demais para uma investida. Com uma gravidade própria, a altura e a rapidez
  afinam-se em separado. Os saltos mais curtos usam a mesma gravidade e o mesmo ângulo: a altura
  diminui na proporção da distância, e o tempo até ao ponto mais alto com a raiz quadrada dela (de
  h = g·t²/2). Ficaram de lado duas alternativas: o mesmo tempo no ar para todos os saltos, em que
  um salto de 200 px andava a 650 px/s, mais devagar do que a personagem corre, e a mesma velocidade
  para todos, que obrigava a mudar a gravidade de salto para salto, e o demónio deixava de ter um
  peso que o jogador aprende.
  Medido pelo `measure_demon.gd` com os valores do nível 1, num salto de 200 px a uma personagem
  parada: 15,22 px de altura (15,2 pela conta) e 0,217 s desde a partida até estar de novo no chão.
  A distância já não se mede aí, porque o demónio para encostado à personagem, a cerca de 122 px; o
  `test_demon.gd` verifica-a com a colisão entre os dois desligada. A física avança em passos inteiros, e o chão trava o demónio até um passo
  depois de ele lá chegar. Por isso, a velocidade horizontal conta com meio passo a mais, e o salto
  aterra até meio passo antes ou depois da distância pedida; neste salto, meio passo são cerca de
  8 px, pela conta. Na subida, a velocidade leva uma correção de meio passo de gravidade: sem ela,
  um salto de 40 px em 0,15 s subiria 44,44 px (medido no `test_demon.gd`).
- **Lógica separada do aspeto.** O demónio só anuncia o que faz, pelos sinais `state_changed`,
  `warning_started`, que diz que ataque vem, e `attack_landed`, quando a pancada acerta. A arte e o
  som escutam-nos. Hoje, o retângulo
  provisório (`demon_placeholder.gd`) muda de forma e de cor no aviso, por uma ligação feita na
  cena, e sai quando a arte chegar. A forma, e não só a cor, distingue a mordida do salto, para
  quem não distingue as cores. A marca por cima da cabeça (`demon_mark.gd`) e os sons
  (`demon_sounds.gd`) escutam da mesma forma, sem que o `demon.gd` mude (ADR 0040).
- **Afastamento pelo crucifixo.** O demónio tem o componente `Repellable` (ver "Crucifixo:
  componentes e modificadores de movimento"). O toque do crucifixo erguido atira-o uma vez, em
  qualquer estado, para longe do crucifixo, com os mesmos valores do arremesso de quando a
  personagem se solta (o grupo Thrown do `DemonStats`); no ar, só na horizontal. Depois de aterrar,
  fica parado durante o Repelled Time, contado nos seus próprios passos de física, pelo que uma
  pausa não o encurta. Antes, o crucifixo empurrava-o enquanto estivesse no raio, e contar a
  duração a partir do último empurrão obrigava a ter em conta a ordem pela qual os dois nós corriam
  em cada passo; com um só toque, o demónio conta apenas os seus próprios passos. O arremesso nunca
  sobe a meio de um salto: um empurrão a meio de um salto rápido chegou a levar o demónio
  a 133,66 px de altura, acima dos degraus que o travam (medido no `test_demon.gd`, antes da
  correção).
- **Pancada e agarrão em componentes.** O ataque passa por dois componentes de `scenes/characters/components/`: a
  `Hitbox`, no demónio, na camada `enemy_hitbox`, ligada só enquanto o ataque pode acertar e com o
  dano e o arremesso do ataque; e a `Hurtbox`, na personagem, na camada `player_hurtbox`, que é a
  única que procura. Na personagem, o `HitReaction` decide entre tirar SP e agarrar, o `GrabEscape`
  conduz o agarrão, as `GrabRules` contam os toques e o tempo, o `InvulnerabilityBlink` faz piscar o
  desenho e o `GrabPrompt` mostra o que premir. As `GrabRules` não usam nós nem cenas, e por isso o
  `test_grab_rules.gd` verifica-as sozinhas, a 60 e a 120 passos por segundo. O demónio não conhece
  o código da personagem: um inimigo novo só precisa de uma `Hitbox`. Para a imobilizar, o
  `GrabEscape` junta um modificador de movimento, o mesmo do crucifixo, que lhe tira a corrida e o
  salto, a um `hold_still()` do `Player`, que lhe anula a velocidade horizontal e a subida, acaba o
  voo de uma pancada, a tira de uma parede e impede que, de pé em cima de um demónio, seja empurrada
  para o lado. O modificador sozinho não chegava: a travagem da corrida é proporcional à velocidade
  máxima, e com a velocidade máxima a 0 a personagem agarrada continuava a 720 px/s (medido no
  `test_grab_escape.gd`, antes da correção). A invulnerabilidade da `Hurtbox` pode deixar entrar
  uma `Hitbox` que a penetre: o piscar depois de uma pancada deixa entrar os ataques dos demónios
  do nível 1, e o segundo depois de um agarrão não deixa entrar nenhum (ADR 0055), salvo a mordida
  nas costas dos cães, que entra em qualquer invulnerabilidade, mas não com a `Hurtbox` fechada
  (ADR 0056). A mordida nas costas usa as mesmas peças. O `DemonBackBite`
  (`scenes/characters/demon/demon_back_bite.gd`) procura o corpo da personagem num espaço com a largura do cão e
  48 px de altura, por cima das costas, alto o bastante para a encontrar antes de ela aterrar, mesmo
  a cair à velocidade máxima. Liga a sua `Hitbox` em cada passo em que ela está em cima do cão,
  segundo a colisão do último movimento dela, desde que tenha passado Back Bite Interval desde a
  última mordida nas costas que a acertou, de qualquer cão (#271). Guarda esse passo num registo
  partilhado por todos os cães, pelo identificador da personagem, e por isso dois cães nunca a
  mordem mais depressa do que um. Nunca morde quem só lhe toca de lado ou por baixo, nem quem o
  atravessa. A primeira mordida a acertar arruma as que outros cães tenham ligado para ela, e assim,
  entre dois cães, só um morde de cada vez. Enquanto a mordida está ligada, o cão está no grupo
  `can_be_stood_on` do `KnockOff`, e a personagem não é empurrada para fora dele. Só a personagem
  pede ao `KnockOff` que poupe esse grupo; os demónios só verificam a camada da personagem, que
  nunca está no grupo. Ao ligar a mordida, vê se ela cabe ao lado do cão, do lado para onde seria
  atirada; se uma parede não deixar, a `Hitbox` atira-a para o outro lado (`knockback_side`). A
  `Hitbox` só entra na física enquanto está ligada, e num demónio sem a mordida o `DemonBackBite`
  fica todo fora da física. Um cão que ainda não a tinha visto e a agarra pelas costas fica com ela
  como alvo, porque o GRAB larga quem não tem alvo (ADR 0056).
- **Matilha sem coordenador.** Cada demónio decide sozinho, com uma área que encontra os outros
  demónios à sua frente, um sorteio próprio da espera antes de atacar e velocidades próprias. A vez
  de atacar (ADR 0053) também dispensa um nó coordenador no nível: os demónios partilham um registo,
  uma variável estática da classe `Demon`, com a lista dos que têm a vez de atacar cada personagem.
  Cada um sai da lista quando morde, quando deixa de poder atacar ou de chegar mais perto dela e
  quando sai da cena, e a lista
  de uma personagem apaga-se quando fica vazia, para que nenhum lado fique bloqueado por um demónio
  que já não ataca. O número de demónios por lado está no `.tres` (Attackers Per Side, 1 no nível
  1); com 0, atacam todos ao mesmo tempo. Quando o agarrão está cheio, a `Hurtbox` fecha-se, um estado separado da invulnerabilidade, para que
  nenhuma pancada entre sem que a personagem pisque. O demónio guarda a `Hurtbox` da personagem ao
  começar a persegui-la e não ataca enquanto nenhuma pancada sua pode entrar.
- **A personagem antes dos demónios.** No Godot, cada corpo vê os outros onde eles estavam no
  início do passo. Com a personagem e o demónio a colidir, isso deixava o demónio entrar no espaço
  que a personagem acabara de ocupar, e os dois tremiam 2 px a empurrar-se. A personagem tem por
  isso uma prioridade de física mais baixa (Process Physics Priority −1), e move-se antes dos
  demónios em cada passo.
- **Afundar com um shader.** O afundar corta o desenho na linha dos pés, com um shader
  (`scenes/others/shaders/sink.gdshader`) que o componente `SinkingDrawing` controla. Mover os corpos para
  baixo exigia, em todos os níveis, um chão com pelo menos 96 px de espessura onde um demónio
  agarra, e numa plataforma fina a personagem saía por baixo. O valor do shader não passa pela
  physics interpolation, que só move posições, por isso o desenho volta ao sítio no próprio passo
  em que a personagem se solta. Cada demónio tem o seu material, e um a afundar não afunda os
  outros.
- **Recomeçar a sala.** Quando a personagem morre, o nível é substituído por uma cópia nova da sua
  cena (ver "Estrutura"). Repor cada sistema à mão (a personagem, os SP, os demónios, a câmara)
  pedia código de reposição em todos eles, e cada sistema novo podia esquecê-lo; a cópia nova está
  sempre como no início, e por isso cada demónio recomeça no seu posto.
- **Posto e regresso (ADR 0032 e 0043).** O posto é a posição onde o nível pôs o demónio, com a
  altura do chão em que assenta, e nunca muda. Com Return Speed acima de 0, quem desiste volta lá a
  passo; a 0, fica onde desistiu, como antes. Se o fim do chão ou uma parede o parar pelo caminho,
  como depois de o crucifixo o atirar para outro chão, fica nesse sítio e faz aí a ronda até voltar
  a desistir, altura em que tenta de novo o posto. Com Jump Height ou Max Drop (ADR 0042), o
  demónio guarda o caminho por onde saiu do chão de casa, um passo por cada vez que aterra noutro
  chão (salto, queda ou arremesso), e no regresso refá-lo do último passo para o primeiro. Um passo
  que não consegue desfazer, como uma queda mais alta do que o Jump Height, deixa-o nesse chão, com
  a mesma regra. Inicialmente, esse sítio passava a ser o posto
  definitivo. Foi abandonado porque apagava o lugar que o nível escolheu para cada demónio: um
  demónio que regressasse ao chão de casa, a saltar atrás da personagem (ADR 0042), ou que visse
  sair do caminho a parede que o travara, ficava para sempre longe do posto. A alternativa de ficar
  parado à borda, sem ronda, deixava-o virado para um chão a que nunca chega, precisamente o que o
  desenho do nível 1 quer evitar. Só contam as paredes do mundo (corpos estáticos e tiles), e não o
  corpo da personagem. Num nível, um posto fica a mais de 30 px de uma borda, o alcance do raio que
  procura o chão; mais perto, o demónio para antes de lá chegar.
- **Fora de alcance e ronda (ADR 0033).** Antes, um demónio que via a personagem num degrau alto
  corria até ficar por baixo dela e acompanhava-a de um lado para o outro, e sem ninguém à vista
  ficava imóvel, como se estivesse desligado. O alcance não é um valor novo: é a maior diferença de
  altura dos seus ataques (hoje 24 px), para que os dois números nunca se contradigam. A personagem
  conta acima e abaixo do demónio, e só com o demónio no chão: um demónio a cair ainda está a
  chegar ao seu chão. A personagem
  só fica fora de alcance quando está num chão, ou a deslizar ou agarrada a uma parede: no ar, ou a
  roçar uma parede a subir, só pode voltar a descer, e um salto para fugir nunca para a perseguição
  nem corta uma mordida a meio. Depois de desistir, o demónio passou a ignorá-la enquanto ela
  estivesse acima do seu alcance, porque voltava a vê-la no passo seguinte e recomeçava a
  perseguição de 2 em 2 s; o ADR 0044 tirou essa trava (ver abaixo). Para voltar a perseguir basta que ela desça ao
  alcance, mesmo no ar; esta diferença entre a regra de entrada e a de saída evita que o demónio
  pare e arranque aos solavancos com a personagem numa chaminé. A ronda é um estado próprio
  (`PATROL`), e o parado (`IDLE`) passa a ser também a pausa nas pontas, para que a arte tenha uma
  animação para andar e outra para estar parado. Cada demónio sorteia as suas pausas, e por isso
  dois demónios postos lado a lado depressa deixam de andar ao mesmo ritmo. Em ronda, os demónios
  não guardavam distância entre si, e dois troços sobrepostos deixavam-nos atravessar-se; desde o
  ADR 0046, viram a Pack Spacing de outro, como numa parede. Continua a ser regra do desenho dos
  níveis que os troços de dois demónios no mesmo chão não se sobreponham, e o teste das regras dos
  níveis, a fazer com o gerador do nível 1, vai verificá-la. Com Patrol Width a 0, o demónio fica parado no posto,
  como antes. Fora do ecrã, não anda, para que o jogador encontre cada demónio perto de onde o nível
  o pôs e para que os demónios que não se veem custem o mínimo.
- **Alerta e procura (ADR 0035).** Antes, o demónio passava de parado a perseguir no mesmo passo,
  sem aviso, e quando uma parede escondia a personagem continuava 1,5 s a correr para onde ela
  estava de facto, sem a ver, e depois esquecia-a. O alerta é o momento em que a arte e o som vão
  mostrar que a personagem foi vista, com o ladrar e um sinal visível; enquanto o demónio for um
  retângulo provisório, o alerta vê-se por um "!" e ouve-se por um bip (ADR 0040). A procura troca esse conhecimento que o
  demónio não devia ter por uma memória: a última posição em que a viu. Por isso, o tempo às cegas
  desceu para 0,5 s, menos do que os 2,5 s de procura, e o teste dos valores do nível verifica essa
  ordem. Só uma parede leva à procura; longe demais, fora do ecrã ou com a personagem morta, o
  demónio desiste como antes. Com Alert Time e Search Time a 0, o demónio comporta-se como antes,
  e é assim que os casos antigos do `test_demon.gd` o usam.
- **Borda do ecrã, matilha e personagem destruída (ADR 0038).** Três correções ao comportamento dos
  passos anteriores. Com um único limite para começar e para continuar a perseguição, um demónio na
  borda do ecrã alternava entre perseguir e voltar ao posto. Agora começa a perseguir apenas dentro
  do ecrã, e só desiste quando está a mais de Screen Margin (160 px) fora dele. Um tempo de espera
  depois de desistir ficou de lado, porque deixaria no ecrã um demónio a ignorar a personagem.
  Um demónio parado, em ronda, a voltar ou a procurar, entre outro e a personagem, travava a
  perseguição desse outro, e dois a procurar no mesmo sítio ficavam um em cima do outro (ver a
  matilha, acima). Com a personagem destruída, como num recomeço que a substitua por uma nova, um
  demónio a meio do aviso saltava para onde ela estivera, e um que a agarrava ficava preso no
  agarrão. Agora larga-a e fica no sítio, ou volta ao posto. Hoje, o recomeço recarrega o nível e
  liberta também os demónios, por isso esta correção protege o caso futuro de um recomeço que
  substitua apenas a personagem; fica nos estados, e não no código do agarrão, para não alterar o
  combate. Custo, com 50 demónios a perseguir, em
  duas execuções alternadas com a versão anterior: o tempo dos scripts passou de cerca de 0,95 ms
  para 1,03 ms em média, dentro do orçamento, e o pior passo chegou a 1,92 ms, perto dos 2 ms. A
  ronda não mudou.
- **Fora de alcance sem ficar hirto (ADR 0039).** Parado e imóvel, um demónio com a personagem fora
  de alcance não mostrava o que pretendia. O desenho do nível 1 pede que um inimigo seja sempre
  plausível e que a intenção se leia na animação e no som. Agora, o demónio anda num troço de Out Of
  Reach Pace Width (160 px) à volta do sítio onde parou, à velocidade da ronda. Ao parar, e em cada
  ponta, fica entre 0,6 e 1,2 s virado para a personagem e ladra. Se uma parede ou a borda do chão o
  trava do lado dela, salta no sítio. Seguir o x da personagem por baixo dela ficou de lado, porque
  a imita e treme quando ela para por cima. O salto é só do desenho, e o corpo fica no chão, para
  não mudar a física, o alcance nem os ataques. O ladrar é um sinal (`barked`), a que a arte e o
  som vão responder; até lá, o retângulo provisório dá um pequeno salto, maior junto à parede.
  Enquanto está fora de alcance, o tempo em que um rebordo ou uma parede esconde a personagem não
  conta para desistir, porque o demónio sabe que ela subiu ou desceu ali. Sem isto, um demónio
  que andasse por baixo de uma prateleira perdia-a de vista, ia procurá-la, voltava a vê-la e
  recomeçava, sem nunca desistir, e não chegava a saltar contra a parede por baixo dela. Desistia
  ao fim de 3 s (antes 2 s), o que dá tempo a pelo menos dois ladridos; desde o ADR 0044, os 3 s só
  contam com a personagem fora da sua vista. Cada pausa é sorteada, para
  dois demónios não ladrarem a par; evitar que dois ladridos simultâneos soem como um é tarefa do
  áudio. Com Out Of Reach Pace Width a 0, o demónio fica parado como antes.
- **Alerta e procura à vista e ao ouvido (ADR 0040).** O alerta durava 0,3 s e não se via nem se
  ouvia, pelo que a personagem não sabia que tinha sido descoberta. Agora, o nó `Mark` mostra um "!"
  no alerta e, com Shows Search ligado, um "?" na procura. Desde a linha de vista, Shows Search está
  desligado por decisão do autor (ADR 0064): a procura fica só com os bips, e quem joga sem som deixa
  de ter um sinal dela no ecrã. As marcas são brancas e com contorno escuro, para não se confundirem com as cores
  do aviso de ataque; distinguem-se pela forma e não pela cor. Cada marca surge maior e encolhe uma
  única vez, sem piscar. O "!" fica Alert Linger Time (0,5 s) já na perseguição, porque 0,3 s mal
  chega para ler. Qualquer outro estado apaga a marca no mesmo passo, e uma pausa suspende a
  contagem. O nó `DemonSounds` tocava um bip no alerta e dois bips a descer na procura, e tem um lugar
  vazio para o ladrido; os bips estão hoje desligados, e o alerta tem o som do cão (ver "Sons no
  mundo: os cães-demónio"). Cada demónio tem uma voz própria, até 8% acima ou abaixo do tom normal, e
  cada som varia até 2%. A marca e o som cobrem-se um ao outro: quem não ouve vê a marca, e quem não
  está a olhar ouve o alerta. O som usa um gerador de números próprio. Com o gerador global, o som
  tirava números de que cada demónio se serve para a sua semente, e mudava o comportamento nos
  testes com semente fixa. Os valores da marca ficam no Inspector da cena do demónio. Custo, com 50
  demónios alertados no mesmo passo (headless, à corrente): a marca acrescenta cerca de 0,2 ms
  nesse passo e nos dois seguintes. Arrancar 50 sons custava cerca de 2 ms nos dois passos
  seguintes. Por isso, todos os demónios juntos arrancam no máximo Max Notice Sounds Per Step (3)
  sons de alerta ou de procura por passo de física, e os restantes ficam em silêncio. Os ladridos
  contam à parte (Max Barks Per Step, 2), para que um ladrido, que só diz que a personagem está fora
  de alcance, nunca cale um demónio que acabou de a ver. Com o limite, os dois passos depois do
  alerta custam 0,32 ms (mediana; pior 0,6 ms) para a marca e o som juntos. Um bando que vê a
  personagem ouve-se como um só, e as marcas continuam a mostrar quais a viram. Um demónio com
  Alert Time 0 persegue logo, sem alerta, e por isso sem marca nem bip, como antes do ADR 0035.
- **Subir e descer atrás da personagem (ADR 0042).** Dois estados próprios, `JUMP` e `DROP`, para
  que a arte e o som distingam a subida da descida, e dois valores no `DemonStats`, Jump Height e
  Max Drop, a 0 por omissão: desligado, o custo é uma comparação por passo e o demónio faz o que
  fazia. A perseguição pergunta primeiro ao `follows_off_its_floor()` se ainda pode ir atrás da
  personagem fora de alcance; a regra do alcance não mudou. Para subir, um `test_move` procura uma
  parede no caminho ao nível do chão e o raio `StepCheck` mede o topo do degrau; o salto usa a
  gravidade da primeira estocada dos ataques, para ser o mesmo salto (sem estocada, não salta), e
  descola onde os pés passam a quina 6 px acima do topo. Para descer, antes de descolar joga o arco
  passo a passo com `test_move` e a mesma integração do motor, e só salta se aterrar num chão mais
  baixo e até Max Drop: 17 a 23 µs por tentativa numa queda de 240 px (três execuções), e a
  perseguição só a pede ao chegar à borda. Um salto que aterra no chão de onde partiu deixa-o fora
  de alcance, para nunca saltitar contra o mesmo degrau. O caminho de volta está na classe pura
  `DemonPath` (um passo por chão com outro y, até 8, esquecendo o mais antigo), e o `RETURN`
  desfaz o último passo. Ficaram de lado: um salto de ataque sem sair do chão, barato, mas que não
  vai atrás dela; saltar buracos, porque os refúgios não precisam deles; e mudar o posto para onde
  a perde, porque espalha os demónios e tira a quem desenha o sítio de cada um. O demónio emite
  `took_off` e `landed`, a que o retângulo provisório e o `DemonSounds` respondem (no máximo 2 sons
  de salto por passo de física, para todos), e o F3 desenha o caminho guardado, numerado pela ordem em que
  se desfaz. Limites conhecidos: dois chãos à mesma altura contam como o mesmo; fora de alcance, não
  volta a tentar se a personagem andar para cima de um degrau a que chega; sem testes a 120 Hz nem
  com plataformas de sentido único como chão de partida ou de chegada.
- **Nunca desiste enquanto a vê (ADR 0044 e 0045).** Desistir ao fim de 3 s com a personagem à
  vista trazia de volta o ciclo procura e alerta do ADR 0039: a quina de uma plataforma esconde-a
  ao pé dela e o demónio perdia-a 0,5 s depois. Saiu a trava que a ignorava depois de desistir; o
  tempo sem a ver conta contra Out Of Reach Wait (3 s) fora de alcance e contra Give Up Time no
  resto. Consequência para o desenho: um sítio alto deixa de ser seguro por si; para fugir, a
  personagem tem de sair da vista. Quando ela sai do troço de 160 px por cima dele, o demónio corre
  pela perseguição até debaixo do último x visto e anda aí; os passos dela dentro do troço não o
  mexem, para não a espelhar.
- **Separação da matilha (ADR 0046).** Antes, dois demónios podiam ficar sobrepostos, parados ou em
  ronda. Agora, no chão e fora de uma investida, de um salto, de uma descida ou de um arremesso,
  cada demónio afasta-se a Pack Push Speed (150 px/s, a da ronda) do vizinho mais próximo a menos
  de Pack Spacing do seu corpo, nunca para fora de uma borda; no mesmo x, desempatam pelo
  identificador. A ronda, o regresso e o troço fora de alcance param ou viram a essa distância. As
  exceções da matilha (ADR 0024) mantêm-se: quem recua e quem ele atravessa não se empurram, nem
  dois com o corpo da personagem entre eles. É a separação de Reynolds (1987), só no eixo x. Ficam
  sobreposições de passagem (cruzamentos ao recuar) ou sem espaço, como num buraco de um corpo. Na
  caça, com a personagem à vista, um demónio em movimento passa pelos outros, e só um encostado a
  ela o trava (ADR 0053); parado, afasta-se como os outros, e no vaivém vira junto de um parado.
  Com corpos de tamanhos diferentes, como o cão normal e o cão grande, cada distância conta a metade
  de cada um dos dois corpos, para que o espaço entre eles seja sempre Pack Spacing (#271). Antes,
  cada demónio tomava o vizinho por um do seu tamanho: o cão normal não reconhecia o grande como
  encostado à personagem e atravessava-o, e o grande parava a 38 px de um normal em vez de 24
  (`test_mixed_pack.gd`).
- **Sem tremer num aperto (#271).** Com três cães entre uma parede e a personagem encurralada contra
  outra, não há posição que cumpra a separação, a distância de recuo e a vez de atacar ao mesmo
  tempo, e as regras alternavam a cada passo: cada cão voltava para trás 48 a 59 vezes em 10 s,
  algumas de um passo para o seguinte. Agora, enquanto a personagem fica do mesmo lado, um demónio
  não volta para trás antes de Min Turn Time (0,15 s, nos `DemonStats`) desde a última volta, e
  fica parado até lá. A investida, o arremesso, o salto, a descida, o recuo depois de uma mordida e
  a passagem da personagem para o outro lado continuam a virá-lo de imediato. O valor fica acima
  das voltas do tremor (1 a 6 passos) e abaixo do troço mais curto do vaivém (0,22 s: 60 px à
  velocidade mais alta que a variação dá à ronda), por isso o vaivém nunca espera. Com 0,25 s, a
  matilha mordia 10 % menos. No mesmo caso, cada cão volta agora 39 a 43 vezes em 10 s, e a volta
  mais rápida passou a 9 passos (`test_wedged_dogs.gd`). O cão deixa de tremer, mas o conflito
  continua: no aperto, ainda volta cerca de 4 vezes por segundo e fica sobreposto a outro.
  Resolver o conflito entre as regras, uma a uma, mexia nos ADR 0046 e 0052 a 0055 e ficou de fora
  (ADR 0070). Custo das duas mudanças, medido pelo `measure_demon.gd` (três execuções de cada
  versão, alternadas, no mesmo computador): com 50 demónios no ecrã, +9 a +16 % por passo (a
  perseguir, 3291 para 3761 µs; em ronda, 1849 para 2150 µs); com 10, +2 a +11 %; com 50 parados
  fora do ecrã, nada (996 para 999 µs). Cerca de um terço vem da espera nas voltas e o resto da
  conta com os dois corpos em cada par de demónios. Entre execuções, o mesmo caso varia até 10 %.
- **Ninguém fica em cima de ninguém (ADR 0047).** O componente `KnockOff`
  (`scenes/characters/components/knock_off.gd`) diz para que lado empurrar quem está de pé em cima da personagem ou
  de um demónio; quem o usa põe a velocidade (600 px/s nos dois). Antes, o demónio não tinha
  empurrão e podia ficar para sempre na cabeça da personagem. Num buraco de um corpo, o empurrão
  batia nas duas paredes e virava a cada passo: agora, se continuar em cima 6 passos (0,1 s) depois
  de bater dos dois lados, os dois corpos deixam de colidir até as caixas estarem a mais de 2 px.
  Com as caixas sobrepostas, o demónio não começa ataques e a `Hitbox` não acerta. Escolheu-se dar
  ao demónio o empurrão que a personagem já tinha (ADR 0022), num componente partilhado, para que
  haja uma só regra para os dois; projetar o demónio e uma regra de desenho dos níveis ficaram de
  lado. O demónio só pergunta ao `KnockOff` com a personagem dentro da sua área de visão, onde ela
  tem sempre de estar para ele lhe estar em cima, ou no passo a seguir a ter sido empurrado: se ela
  desaparecer de baixo dele, por um respawn ou pelas teclas da sala de treino, o empurrão acaba em
  vez de ficar preso (ADR 0049; o custo medido vem mais abaixo, nesta secção). Quem vai a subir,
  como a personagem atirada por uma pancada desde o passo anterior, já está a sair de cima e não é
  empurrado: sem isso, o empurrão apagava o arremesso, e ela subia 0,1 px em vez de 40 com o de uma
  mordida (ADR 0056). Quem está agarrado também não é empurrado: atravessa logo o corpo em que está
  de pé, e o seguinte, se estiver em cima de dois, para que nenhum agarrão a segure em cima de um
  cão; cai até ao chão e afunda-se lá (ADR 0056). Por isso o `KnockOff` atravessa vários corpos ao
  mesmo tempo, cada um até as caixas se afastarem. A personagem também não é empurrada de cima de
  um cão que morde quem lhe está em cima: leva uma mordida a cada 0,4 s até sair a andar ou a
  saltar, e já não desliza pelas costas da matilha (#271).

Antes de decidir se a perseguição precisava de ser otimizada, fixaram-se dois limites para 50
demónios a perseguir ao mesmo tempo, muitos mais do que um ecrã terá: um limite para a média por
passo de física, um pouco acima do medido, para que um aumento de custo se note cedo, e 2 ms no pior
passo, a parte de um passo de 16,6 ms que um sistema pode ocupar. Mede-se com o `measure_demon.gd`,
com todos os demónios a ver a personagem parada e a persegui-la: um de cada vez ataca, e os outros
esperam enquanto ela pisca, o caso mais exigente que o jogo permitia (desde o ADR 0055, a medida é
outra, descrita no fim desta secção). Cada parte da medida começava com uma personagem nova, com o
SP cheio, para que nenhum agarrão a deixasse presa a meio. O custo é o que
os demónios acrescentam ao passo inteiro, incluindo o motor de física, numa sala sem eles. Com os
valores atuais do nível 1, depois da pancada e do agarrão (2026-10-20 e 2026-10-21):

| Demónios a perseguir | Média por passo | Pior passo | Execuções |
|---|---|---|---|
| 10 | 0,26 a 0,36 ms | 0,50 a 0,87 ms | 5 |
| 50 | 1,15 a 1,32 ms | 2,20 a 2,67 ms | 5 |
| 200 | 11,9 a 14,4 ms | 21,9 a 24,5 ms | 5 |

Antes da pancada e do agarrão (sete execuções, no mesmo dia), 50 demónios acrescentavam 1,15 a
1,20 ms em média e 1,38 a 1,76 ms no pior passo. A média quase não mudou, mas o pior passo subiu
0,6 a 0,9 ms e passa agora os 2 ms. Nesse pior passo, nenhum demónio começa o aviso, ao contrário do
que acontecia com os primeiros ataques (ver a seguir). A causa da subida ainda não foi medida no
Profiler; o que a pancada e o agarrão acrescentaram a cada demónio foi a área que encontra os outros
demónios, a `Hitbox` e a colisão com a personagem.

Com os primeiros ataques (2026-10-19), em que todos os demónios saltavam à mesma distância, a média
com 50 demónios era de 0,43 a 0,51 ms e o pior passo de 1,67 a 2,50 ms. O pior passo era aquele em
que dezenas de demónios começavam o aviso juntos, procurando o chão ao longo do salto: em 4 de 5
execuções, 36 dos 50. Com a probabilidade por segundo, os avisos espalham-se, e no pior passo
começaram de 1 a 12. A média subiu porque os demónios passam agora quase todo o tempo a perseguir,
em vez de parados no aviso e depois do salto. Numa medida à parte, com o método do
`measure_demon.gd` e os ataques do `.tres` alterados (três execuções), 50 demónios a perseguir sem
ataques acrescentaram 1,12 a 1,15 ms, com a mordida e o salto 1,15 a 1,19 ms, e 50 parados, longe
da personagem, 0,49 a 0,50 ms. Um demónio a perseguir custa cerca de 23 µs por passo, com o
movimento e os dois raios, e um parado cerca de 10 µs: o custo é a perseguição. Os ataques
acrescentam cerca de 0,04 ms em média, dentro da variação entre execuções.

Com esses ataques, decidiu-se aceitar o custo, porque o pior passo ficava abaixo dos 2 ms, e subir o
limite da média de 1 para 1,5 ms, cerca de um quarto acima do medido: um limite que falha sempre
deixa de avisar. Com a pancada e o agarrão, a média continua dentro desse limite, mas o pior passo
já não fica abaixo dos 2 ms. Decidiu-se aceitá-lo até haver um nível para medir: 50 demónios a
perseguir ao mesmo tempo são um teste de esforço, muito acima do que um ecrã terá, e o limite da
média, que serve de alarme, continua cumprido. A causa da subida mede-se no Profiler antes do
nível 1. Os 200 demónios a perseguir ao mesmo tempo ocupam quase um passo inteiro
em média e passam-no no pior passo, pelo que um nível deve ter, no máximo, algumas dezenas a
perseguir ao mesmo tempo. Quando o nível 1 tiver os seus demónios, mede-se o caso real. Se aí um
passo ultrapassar os 2 ms, a resposta preparada é repartir o trabalho da perseguição: cada demónio
confirma a linha de vista num passo em cada dois ou três, à vez. Os valores foram medidos com o
executável do editor do Godot, num só computador, e o pior passo variou entre execuções: com 50
demónios, de 2,20 a 2,67 ms, e com 200, de 21,9 a 24,5 ms.

Com os sentidos novos e o regresso ao posto (2026-10-26, duas execuções de cada, no mesmo
computador e no mesmo dia), 50 demónios acrescentaram:

| Versão | Média por passo | Pior passo |
|---|---|---|
| Antes, código e valores anteriores | 0,82 ms | 1,42 a 1,47 ms |
| Código novo, valores anteriores | 0,79 a 0,83 ms | 1,47 a 1,57 ms |
| Código novo, valores novos | 1,06 ms | 2,24 a 2,26 ms |

O código novo não custa mais. O que sobe o custo são os valores: com só a visão e a perda maiores,
o pior passo deu 2,16 a 2,26 ms; com só o regresso e os 20 % para trás, 1,88 a 1,99 ms. Com eles,
há mais demónios ativos ao mesmo tempo, porque largam menos a personagem e andam de volta em vez
de ficarem parados. O pior passo volta a passar os 2 ms, e mantém-se a decisão anterior: 50
demónios atrás da mesma personagem são um teste de esforço. Num nível, a regra do ecrã deve
limitar os ativos aos que estão à vista, mas isso ainda não foi medido: a medida corre sem câmara,
e por isso todos contam como estando no ecrã. Mede-se com o nível 1. A média continua abaixo do
limite de 1,5 ms. Para que a medida
continue a pôr todos os demónios a perseguir, cada um é colocado virado para a personagem.

Com o "fora de alcance" e a ronda (2026-10-26, no mesmo computador e no mesmo dia), a medida ganhou
duas partes, com 50 demónios em ronda e a personagem fora da vista de todos. Na primeira, sem
câmara, todos contam como estando no ecrã e todos andam: é um teste de esforço. Na segunda, os
demónios estão espalhados por dez ecrãs (19 200 px), com uma câmara ao meio, como num nível: só os
que estão no ecrã andam, 4 dos 50 no fim da medida.

| 50 demónios | Média por passo | Pior passo | Execuções |
|---|---|---|---|
| A perseguir, antes | 1,11 ms | 2,20 ms | 1 |
| A perseguir, depois | 1,07 a 1,23 ms | 1,96 a 4,81 ms | 5 |
| Em ronda, todos no ecrã | 1,37 a 1,71 ms | 2,36 a 3,04 ms | 5 |
| Em ronda, espalhados por dez ecrãs | 0,48 a 0,85 ms | 1,05 a 1,52 ms | 5 |

A média a perseguir ficou igual: a nova verificação é uma comparação de alturas por passo. O pior
passo de 4,81 ms apareceu numa só execução, com a média igual às outras; a causa não foi medida. Em
ronda, todos no ecrã passam os 2 ms no pior passo em todas as execuções, e a diferença para a
perseguição está no motor de física (0,64 a 0,80 ms, contra 0,23 a 0,31 ms a perseguir), não nos
scripts, que custam o mesmo. A hipótese, por medir no Profiler, é que os demónios em ronda se
atravessam e a área que encontra os outros demónios está sempre a entrar e a sair. Espalhados por
dez ecrãs, a 384 px uns dos outros, os troços também se sobrepõem, e mesmo assim os 50 ficam dentro
dos dois limites, porque só os que estão no ecrã andam. Aceita-se, como na perseguição, até haver um
nível para medir. Nos scripts, cada demónio parado fora do ecrã custa cerca de 13 µs por passo.

Com o ADR 0039 (2026-10-26, ligado à corrente), a medida ganhou uma parte com 50 demónios no chão,
todos a ver a personagem numa prateleira fora do seu alcance, sem câmara: primeiro parados (troço a
0, como antes) e depois a andar no troço de 160 px. É um teste de esforço, porque uma sala do nível
tem poucos demónios.

| 50 demónios fora de alcance | Média por passo | Pior passo | Scripts, média | Execuções |
|---|---|---|---|---|
| Parados | 0,93 a 1,07 ms | 1,68 a 2,87 ms | 0,65 a 0,75 ms | 4 |
| A andar no troço | 1,19 a 1,48 ms | 1,79 a 4,58 ms | 0,76 a 0,98 ms | 4 |

Em cada execução, andar custa 0,23 a 0,41 ms a mais no passo inteiro e 0,11 a 0,23 ms nos
scripts, cerca de 5 a 8 µs por demónio, sobretudo no motor de física, como na ronda. A média fica
dentro de 1,5 ms. O pior passo varia muito de execução para execução, também com os demónios
parados (os valores mais altos de ambas as linhas vêm da mesma execução, com a média também mais
alta), e passa os 2 ms em três das quatro, como na ronda com todos no ecrã. Aceita-se pelo mesmo
motivo, até haver um nível para medir; a causa do pior passo fica para o Profiler.

Com o salto, a separação e o empurrão (ADR 0042, 0046 e 0047; 2026-10-28), a medida ganhou duas
partes com 50 demónios com o salto ligado (96 px e 240 px), metade de cada lado de um bloco com a
personagem ao meio: um bloco de 96 px, que sobem, e um de 144 px, mais alto do que o salto.

O computador passou a medir mais devagar do que a 26 de outubro, sem causa conhecida. O mesmo código
que nesse dia deu 0,95 a 1,03 ms de scripts com 50 demónios a perseguir deu 1,40 a 1,64 ms, depois
de reiniciar, ligado à corrente, sem outros programas abertos e com a poupança de energia ligada e
desligada. Na mesma sessão, os valores subiram até cerca de um terço à medida que o computador
aquecia. Por isso, os limites absolutos deixaram de servir de critério (ADR 0048): a versão do `dev`
e a deste trabalho correm alternadas na mesma sessão (seis execuções de cada), e um trabalho não
pode somar ao `dev` mais do que a margem do limite, cerca de um quarto, nos casos que um nível tem.
A tabela mostra o passo inteiro, em média; a diferença é a mediana das seis comparações.

| 50 demónios, passo inteiro em média | `dev` | Com o salto, a separação e o empurrão | Diferença |
|---|---|---|---|
| Espalhados por dez ecrãs, como num nível | 0,68 a 0,82 ms | 0,79 a 0,96 ms | +13 % |
| A perseguir | 1,99 a 2,31 ms | 2,62 a 3,08 ms | +33 % |
| Em ronda, todos no ecrã | 1,14 a 1,46 ms | 1,38 a 2,10 ms | +22 % |
| Fora de alcance, parados | 1,17 a 1,59 ms | 2,33 a 2,88 ms | +73 % |
| Fora de alcance, a andar no troço | 1,71 a 2,06 ms | 2,57 a 3,08 ms | +54 % |
| Com salto, sobem um bloco de 96 px | | 5,40 a 6,03 ms | |
| Com salto, ao pé de um bloco de 144 px | | 3,31 a 3,53 ms | |

Com 10 demónios a perseguir, o `dev` deu 0,29 a 0,39 ms e este trabalho 0,33 a 0,53 ms: +26 %, no
limite da margem, com cerca de 0,09 ms de diferença.

Antes de otimizar, o caso espalhado por dez ecrãs subia +29 %, acima da margem. Medido por fase do
`_physics_process`, numa cópia instrumentada, cada demónio pagava cerca de 3 µs por passo em
qualquer estado, mesmo parado fora do ecrã: 2 µs na verificação do empurrão, 0,5 µs na da separação
e 0,5 µs no registo do caminho de regresso. Duas condições cortaram as duas primeiras (ADR 0049): um demónio só verifica o empurrão com a
personagem dentro da sua área de visão, onde ela tem de estar para ele lhe estar em cima, e só
procura afastar-se de outros quando tem algum por perto. Com 50 demónios e a personagem longe, a
verificação do empurrão passou de cerca de 100 µs para 21 a 33 µs por passo, e a da separação de 34
a 41 µs para 8 µs; com eles juntos e a personagem perto, o custo ficou igual, porque aí o trabalho é
real. Os cerca de 0,1 ms poupados batem com a descida de +29 % para +13 % no passo inteiro, mas a
variação entre execuções, até ±30 %, não deixa atribuí-la toda a esta alteração. O registo do
caminho de regresso ficou: cortá-lo obrigava a
mudar a forma como o caminho é registado, com risco de perder um degrau, por um ganho pequeno.

Nos outros casos, a subida é o comportamento novo, sobretudo a separação, que custa cerca de 0,4 ms
por passo com 50 demónios a perseguir, medida por fase. Ler as posições uma vez por ciclo não mudou
o custo e foi revertido. A causa é o comportamento:
arrumados, os demónios ficam a cerca de 73 px uns dos outros (medidos; 48 px de corpo e 24 px de
espaço); 50 precisariam de cerca de 3650 px de chão, não os têm e empurram-se sem fim (os 50
continuam a andar no fim da medida, contra 0 no `dev`). A medida com 10 demónios fora de alcance,
que têm chão, mostra-os todos parados no fim, com 0,24 ms. Os 50 apertados em cima do bloco de
96 px são o caso mais caro. Aceita-se a perseguição e o fora de alcance acima da margem porque 50
demónios juntos à volta da personagem, ou sem chão, não são um caso que um nível tenha, e trata-se como regra de desenho, e não como otimização: até 8
demónios ativos no ecrã e chão para cada um onde se juntam (itens 26 e 36 da lista do
`docs/nivel1_desenho.md`). Com 50 demónios do mesmo lado de um degrau, a fila estende-se por
mais de 1200 px, e os últimos ficam a mais de Lose Distance da personagem e voltam ao posto.

Com o vaivém, a vez e os ataques durante o piscar (ADR 0052, 0053 e 0055; 2026-11-10), cada
demónio que espera anda em vaivém perto da personagem, ataca no máximo um de cada lado, e os
ataques acertam também enquanto ela pisca. Uma matilha deixava-a com SP baixos em cerca de 2 s e
agarrava-a, e o resto de cada parte da medida passava a medir demónios a agarrá-la ou à espera, e
não a persegui-la. Por isso, a medida
dá agora a cada personagem nova um máximo de SP muito alto, só em memória, e acaba com código 1
se, mesmo assim, ela ficar com SP baixos. O `dev` e este trabalho correram alternados com a mesma
medida, três execuções de cada, antes e depois de otimizar; a diferença é a mediana das três
comparações:

| Demónios a perseguir, passo inteiro em média | Antes: `dev` | Antes: este trabalho | Depois: `dev` | Depois: este trabalho | Diferença depois |
|---|---|---|---|---|---|
| 10 | 0,29 a 0,30 ms | 0,41 a 0,43 ms | 0,27 a 0,30 ms | 0,40 a 0,41 ms | +47 % |
| 50 | 1,54 a 1,70 ms | 3,09 a 3,27 ms | 1,58 a 1,60 ms | 2,39 a 2,41 ms | +50 % |
| 200 | 14,7 a 19,6 ms | 42,3 a 47,4 ms | 14,6 a 14,9 ms | 24,0 a 24,6 ms | +65 % |

Antes de otimizar, a diferença era de +40 % com 10, +93 % com 50 e +153 % com 200. Medido por fase
numa cópia instrumentada, com 50 demónios, o vaivém era metade do tempo dos scripts: cada demónio em
vaivém percorria a matilha inteira três vezes por passo, para saber se um demónio parado o travava
e quantos andavam sobrepostos a ele. A otimização junta as três perguntas numa só passagem e lê a
posição e a velocidade de cada demónio uma vez, pelos métodos, que no GDScript custam menos do que
as propriedades (medido: 50 contra 76 ns por leitura da posição e 18 contra 37 da velocidade). As
respostas são as mesmas: numa cópia, a versão antiga e a nova correram lado a lado, sem nenhuma
diferença em 61 989 comparações nos testes e 265 780 na medida, e o mesmo arranjo apanhou duas
alterações feitas de propósito (6 996 e 152 diferenças). Com 50 demónios, cerca de 0,3 ms da
diferença que fica é do motor de física (0,58 a 0,61 ms fora dos scripts, contra 0,28 no `dev`),
provavelmente porque os demónios que esperam andam, em vez de estarem parados. O resto, cerca de
0,5 ms, é dos scripts. Numa cópia instrumentada, o vaivém continua a ser a parte mais cara, com
0,53 a 0,54 ms por passo, dos quais 0,32 a 0,33 ms na passagem pela matilha, que cresce com o
quadrado do número de demónios (6,2 a 8,2 ms com 200). Com 10 demónios, a passagem leva cerca de
15 µs por passo e o vaivém 39 a 47 µs, e a origem da diferença de 0,1 ms ficou por medir. Nas
outras partes da medida, a diferença ficou entre -1 % e +15 %, menos ao pé do bloco de 144 px, mais
alto do que o salto: 1,76 a 1,81 ms no `dev` e 2,70 a 2,85 ms neste trabalho (+54 %), já antes de
otimizar, com a causa por medir. A perseguição continua acima da margem de um quarto com 10, 50 e
200 demónios, e aceitou-se (2026-11-10): com 10, a diferença é de cerca de 0,1 ms, menos de 1 % de
um passo de 16,6 ms, e 50 ou 200 demónios juntos à volta da personagem não são um caso que um nível
tenha.

A mordida nas costas dos cães (ADR 0056; 2026-11-10) dá a cada cão uma área que procura a
personagem por cima das costas. Mediu-se como acima, contra o commit anterior, em seis execuções
alternadas de cada, com o PC mais ocupado do que na tabela. Os valores são medianas:

| Parte da medida, passo inteiro em média | Antes | Com a mordida | Diferença |
|---|---|---|---|
| 10 a perseguir | 0,41 ms | 0,44 ms | +6 % |
| 50 a perseguir | 2,64 ms | 3,07 ms | +16 % |
| 200 a perseguir | 29,5 ms | 35,2 ms | +19 % |
| 50 de ronda, sem a ver | 1,16 ms | 1,32 ms | +14 % |
| 50 de ronda por dez ecrãs | 0,69 ms | 0,67 ms | no ruído |

Com os demónios espalhados por dez ecrãs, como num nível, a diferença perde-se no ruído, porque os
que estão fora do ecrã ficam parados, e a área de um demónio parado quase não custa. Um demónio sem
a mordida não paga nada. A primeira versão, com duas áreas em todos os demónios, custava 11 a 15 %
também a esses. Ficou de lado procurar a personagem pela área de visão que o cão já tem: poupava a
área, mas obrigava a uma visão maior do que o cão e a refazer os testes.

A mordida contínua nas costas (#271; 2026-11-19) não mudou o custo de forma mensurável. Em três
execuções alternadas com a versão anterior, as medianas das dez partes da medida variaram entre
−11 % e +26 %, e as execuções da mesma versão já diferem até 34 % entre si. O custo novo só existe
com a personagem por cima de um cão, e a medida nunca a põe lá.

O `test_demon.gd` verifica, com a personagem e o crucifixo verdadeiros, a visão (a distância e as
paredes), a perseguição e a desistência, a paragem nas bordas e nos degraus, o aviso e o seu tempo,
a altura, a distância e a direção do salto, também num salto mais rápido e num de metade da
distância, a recusa de saltar para um buraco, o tempo parado depois do salto, a pontaria (a uma
personagem parada, a uma que se afasta, a uma que vem a correr na direção do demónio, e o cálculo
sem física, também com uma personagem que vem tão depressa que nenhum salto a apanharia), os
valores-limite de um ataque (uma distância mínima acima da máxima, um aviso de 0 s e os valores de
origem de um ataque novo), a mordida a correr, a ordem da lista como prioridade (a mordida antes do
salto, e o salto antes da mordida, que tem o alcance menor), a probabilidade por segundo a duas
frequências de física, na fórmula e no sorteio do próprio demónio, o afastamento pelo crucifixo
(com um demónio por baixo da personagem, um salto contra o crucifixo erguido e um salto rápido
travado a subir), o tempo afastado com uma pausa pelo meio, a recusa de um salto rápido que pode
aterrar depois do fim do chão, o arremesso de uma borda abaixo, o regresso ao estado parado de um
demónio que nunca a viu, e as camadas de colisão. Com a pancada e o agarrão, verifica também a
`Hitbox` (ligada só enquanto o ataque pode acertar, com o dano e o arremesso do ataque), a colisão
com a personagem, o recuo depois de cada ataque, a distância entre demónios em matilha e o ritmo
próprio de cada um, a espera sorteada antes de atacar, a espera enquanto a personagem pisca, o
agarrão com um e com dois demónios, o terceiro que espera à distância, o arremesso quando a
personagem se solta e o atordoamento. Com os sentidos novos e o posto, verifica a cabeça vista por
cima de um muro baixo, o alcance para trás com o demónio virado para cada lado, o ecrã (não começa
a perseguir fora dele e desiste quando sai), o regresso ao posto à velocidade certa, a nova
perseguição a meio do regresso, a paragem noutro chão e contra uma parede sem o posto mudar, o
regresso a casa depois de a parede sair e a ronda à volta do sítio onde parou. Com o "fora de
alcance", verifica que o demónio para virado para a personagem num degrau alto e não a segue
quando ela anda por cima, que numa plataforma alta não corre até à borda por ela estar em baixo, que volta a persegui-la quando ela desce ao alcance, ainda no ar, que
nunca desiste enquanto a vê e, escondida, vai procurá-la ao fim da espera, que um salto
dela no seu chão não para a perseguição e que não avisa de um ataque a uma personagem no ar acima do
seu alcance. Com a ronda, verifica o vai
e vem dentro da largura e à velocidade certas, as pausas dentro dos limites, a volta à beira de um
desnível e contra um degrau, a paragem fora do ecrã, as pausas diferentes de dois demónios, a
perseguição a meio da ronda e a ronda retomada depois do regresso ao posto. O caso do degrau mudou:
antes, o demónio corria até ao degrau; agora para onde a vê. Com o alerta e a procura, verifica que
para virado para ela durante o alerta e só depois a persegue, que a larga se ela morrer a meio,
que vai à velocidade certa até onde a viu pela última vez, fareja ali o tempo certo virando-se para
os dois lados e depois volta ao posto, que fica alerta se a vir durante a procura, que desiste da
procura fora do ecrã e que, perdida de outra forma que não por uma parede, nunca a procura. Com o
ADR 0038, verifica que um demónio que não persegue a personagem não trava outro que a persegue, que
dois a procurar no mesmo sítio ficam à distância de matilha, que a perseguição continua dentro da
margem do ecrã, acaba depois dela e não recomeça fora do ecrã, e que a personagem destruída a meio
do aviso, fora do alcance ou no agarrão deixa o demónio parado, sem saltar. Com o ADR 0039,
verifica que, fora de alcance, o demónio anda no seu troço sem o passar e nunca fica parado mais
do que a pausa mais longa, que ladra virado para a personagem em cada ponta, que salta só contra a
parede ou na borda do lado dela e não passa nenhuma das duas, que continua por baixo de uma
prateleira que a esconde, que sem troço nunca ladra, que dois
demónios com as pausas do nível, em três sementes, ladram a menos de 6 passos um do outro menos de
metade das vezes, que o salto do retângulo deixa o corpo no chão e que uma mudança de estado o
interrompe e o repõe logo. Com os ADRs 0044 a 0046, verifica que segue por baixo quando ela sai do
troço, mais depressa do que a ronda, e que os passos dela dentro do troço não o mexem, e que dois
demónios no mesmo sítio, na ponta de um chão, no troço, em ronda e a agarrar do mesmo lado se
separam. Os casos alterados por estas decisões (seis) foram-no com autorização e estão
registados nos ADRs. Com os ADRs 0051 a 0053, sem alterar nenhum caso antigo, verifica que o
primeiro ataque vem logo a seguir ao alerta, e que o fim do piscar depois de um agarrão e o regresso depois de atirado
pelo crucifixo voltam a sortear a espera. Verifica também que, enquanto espera, o demónio fica
entre 130 e 190 px da personagem, sem parar e à velocidade do vaivém, e vira numa borda e numa
parede; que a mordida que acaba a espera acerta numa personagem parada e nunca é um salto; que três
demónios do mesmo lado nunca ficam parados nem andam como um só, e dois a correr atrás dela também
não; que cinco atacam à vez, no máximo
um de cada lado, e mordem todos; que dois em lados opostos atacam ao mesmo tempo; que o que tem a
vez passa pelo outro para morder; que a vez passa a outro quando quem a tem é atirado, sai da cena
ou fica preso do outro lado de um buraco; que dois encurralados entre uma borda e a personagem
nunca ficam um em cima do outro e continuam a morder; e que o demónio que ataca é desenhado à
frente dos outros. Com o ADR 0055, verifica que cinco demónios do nível nunca passam mais de 4 s
sem atacar e continuam a atacar à vez; que deixam a personagem com o SP baixo em menos de 4 s, em
metade do tempo de um só ou menos; que a mordida e o salto de um demónio do nível acertam enquanto
ela pisca e lhe tiram o SP do dano; que nenhum ataca a personagem agarrada nem no segundo depois
de ela se soltar; e que um demónio sem esse valor espera pelo fim do piscar e que dois a morder
juntos lhe tiram SP uma só vez. O caso da mordida depois da espera passou a contar também as do
piscar, numa janela de 4 s em vez de 5. São 174 casos. Os 24 dos ADRs 0051 a 0053 e 0055 que usam
os demónios do nível e os
oito últimos leem o `.tres` do nível 1; os outros usam valores próprios, pelo que afinar o
`.tres` não os altera. Os 24 confirmam as regras novas com os valores do nível, e os oito últimos
confirmam o
que o desenho dos níveis assume: cada ataque com uma das animações da arte, os saltos e a diferença
de altura para atacar abaixo de um tile (48 px), o Lose Distance acima do Sight Distance e a
perseguição mais lenta do que a corrida da personagem, e a regra do ecrã ligada, com margem, a visão de pelo
menos meio ecrã, menos alcance para trás do que para a frente e o regresso mais lento do que a
perseguição, para que um demónio a voltar nunca pareça vir na direção dela, e a ronda ligada e mais
lenta do que a perseguição, com um degrau de um tile fora do alcance, e o alerta ligado, com o
tempo às cegas menor do que o de procura e a procura mais lenta do que a perseguição, e o "fora de
alcance" com troço e com tempo para pelo menos dois ladridos antes de desistir, mesmo com a pausa
inicial mais longa.

O `test_demon_jump.gd` (30 casos) verifica a subida (degraus de 48 e 96 px sem tocar a parede, com
o pico 12 px acima do topo; 144 px, sem estocada, teto baixo e plataforma por cima não), a descida
(96 e 240 px, a 300 e a 600 px/s; 288 px e teto por cima não), o crucifixo e a personagem destruída
a meio, o regresso pelo caminho guardado, a procura a subir e a descer, e a imagem e os sinais ao
descolar e aterrar. O `test_demon_path.gd` (6 casos) verifica a pilha do caminho sem física. O
`test_stacked_bodies.gd` (10 casos) verifica que nem a personagem nem um demónio ficam um em cima
do outro: saem para o lado, nunca para cima, também num buraco de um corpo, num canto, durante um
agarrão e com o demónio a andar, e com os corpos sobrepostos nenhum ataque acerta. O
`test_dog_back_bite.gd` (23 casos) verifica a mordida nas costas dos cães: logo ao aterrar, com o
SP certo, e outra a cada Back Bite Interval enquanto ela fica, nem antes nem depois, também de outro
cão e sem empurrão; com um intervalo abaixo de 0,34 s nos Stats, as mordidas vêm a cada 0,34 s,
nunca mais de três por segundo; subir para as costas a andar, de um chão à altura delas, também
morde; a matilha que não a leva por cima, nem pelo empurrão nem pela mordida; as duas pontas
das costas, até 1 px; com um arremesso ao longo do chão, o arremesso certo, também entre dois cães
e na borda das costas, de seis alturas, e outra mordida a cada aterragem no mesmo cão; nada de lado, a
atravessar nem numa plataforma logo acima de um cão; o agarrão com o SP baixo, que a faz cair
através do cão, também em cima de dois cães, onde só um a morde e a segura, e a fuga; o buraco
fundo, onde as mordidas acabam num agarrão; o cão junto a uma parede, que a atira para o lado
aberto quando ela não cabe ao lado dele, mesmo por meio píxel, e por cima de uma parede mais baixa
do que ele; qualquer piscar, a `Hurtbox` fechada, o arremesso que o empurrão já não apaga, a
mordida ligada e desligada com o jogo a correr e os valores dos dois cães.

#### Overlay de depuração

Para afinar o movimento durante o jogo, a sala de teste mostra no canto superior esquerdo os FPS e
o passo de processamento e o de física mais lentos do último segundo, valores que o Godot só
atualiza uma vez por segundo, pelo que um único frame lento permanece visível durante um segundo.
Mostra também o estado e a velocidade da personagem e, depois de cada salto, o tipo de salto, as
tolerâncias usadas, em passos de física, e a altura atingida. Um salto completo mostra
240 px, o mesmo valor que os testes medem. Com a câmara ligada, mostra ainda a zona de câmara em que
a personagem está e as distâncias atuais da antecipação e do olhar para baixo, e quantos membros do
`ActivityTracker` estão acordados (ver "Atividade fora do ecrã"). Mostra ainda os SP,
a velocidade atual da regeneração e se os SP estão baixos ou acabaram.

O texto tem páginas, e a tecla F3 passa à seguinte: escondido, números (tudo o que se descreve
nesta secção), luz e shaders, e de novo escondido. Por cima de cada página aparece o nome dela e o
da seguinte. Escondido, o overlay não gasta nada por frame. O nível 1 começa com o texto escondido
e a sala de teste com os números; a página escolhida com o F3 mantém-se quando o mesmo nível
recomeça, depois de uma morte ou de um salto de fase.

A página da luz mostra os valores do protótipo de iluminação do nível 1 e é a única que lhe passa
as teclas F1 a F12, com e sem Ctrl: fora dela, essas teclas não mudam a luz, e numa exportação de
release não chegam ao protótipo. Antes das páginas, o protótipo lia as teclas sozinho e antes do
overlay, pelo que ficava com o F3, o F4 e o F7 a F9, e as teclas de depuração correspondentes não
funcionavam no nível com a luz. Agora, na página da luz, o protótipo continua a ter prioridade
sobre essas teclas, menos o F3 sozinho, que muda de página; a sombra pintada passou do F3 para o
Alt+F3. Nas outras páginas, as teclas de depuração funcionam também nesse nível. As teclas da luz
chegam ao protótipo mesmo com uma fala no ecrã, porque o overlay as recebe antes do balão. O
protótipo deixou de escrever texto próprio no ecrã. Num nível sem o protótipo, a página da luz diz
que não há iluminação para afinar. Teste: `test_lighting_debug_page.gd`, com o protótipo verdadeiro.

Desde a #284, o valor da escuridão (F5/F6) parte de 0,35 (era 0,30), e a gradação de cor (Ctrl+F1)
e o contorno (Ctrl+F6) partem desligados; o código fica, e as teclas voltam a ligá-los. O
`test_level1_lit.gd` verifica estes valores por omissão.

A tecla F4 retira à personagem o valor Debug Damage do overlay (10 SP, no Inspector), como um golpe,
para experimentar a regeneração e os avisos antes de haver demónios. Cada toque conta uma vez,
mesmo com a tecla premida, não atua com o jogo em pausa e funciona com o texto escondido. O overlay
pode ferir a personagem diretamente porque não faz parte do jogo: é uma ferramenta de depuração,
ligada à personagem num só sentido, e sai das exportações de release, pelo que nada no jogo depende
dele. O F4 está reservado nos perfis de controlos, como o F3, porque uma ação do jogo atribuída a
essa tecla feriria a personagem sempre que fosse usada nas versões de depuração.

As teclas F7 e F8 aceitam e recusam a última oferta feita, ou, se ainda não houve nenhuma, a primeira
do catálogo ainda por aceitar, tal como as falas o fariam. Permitem experimentar o atalho ou um dom
sem jogar até lá. A tecla F9 recomeça o estado da partida: ofertas, registo moral, upgrades e
crucifixo. O overlay mostra a oferta em causa, se já foi aceite, as recusas, o estádio moral e se o
homem ainda tem o crucifixo. As três teclas estão reservadas nos perfis de controlos, pelas mesmas
razões do F4.

A tecla F10 troca a câmara para a forma seguinte de enquadrar o homem (#282): a da própria câmara, com
as zonas, e depois cada modo que a cena da câmara tiver (ver «Câmara»; hoje, a câmara de zoom fixo,
`Fixed`, com que o nível 1 começa). Funciona também com o texto escondido, e a forma escolhida mantém-se na cópia seguinte do
nível, como depois de uma morte: a câmara nova começa já enquadrada por ela, sem deslizar. Na página dos números, uma linha própria indica a forma em uso. Na página da
iluminação, a F10 pertence ao rig, como as restantes teclas F. Está reservada nos perfis de controlos,
pelas mesmas razões do F4, e o balão das falas deixa-a passar, como às outras teclas de depuração.

As teclas F1 e F2 ligam e desligam duas ajudas de depuração, para atravessar e experimentar os
níveis sem morrer. Com o god mode (F1), os golpes dos demónios acontecem como no jogo (o piscar, o
tremor, o empurrão e o agarrão), mas não retiram SP; nada mata a personagem, e um agarrão que
esgote o tempo larga-a em vez de a matar. Com o noclip (F2), a personagem voa com as teclas de
movimento, também para cima e para baixo, a 1200 px/s (Noclip Speed, no Inspector do overlay), sem
gravidade e através das paredes e do chão. Enquanto voa, os golpes não têm efeito, nada a mata e
um agarrão em curso larga-a; os contactos continuam, no entanto, a ser detetados, pelo que o
tremor do ecrã e a vibração do comando de um golpe se mantêm. Ao desligar, cai do sítio onde está.
As duas funcionam com o texto escondido, com o jogo em pausa e com uma fala no ecrã, e uma etiqueta
no canto superior direito indica as que estão ligadas. Na página da luz, o F1 e o F2 são do
protótipo de iluminação, como as outras teclas que ele usa, e não mexem nas ajudas. Ficam ligadas depois de uma morte, de um
recomeço ou de um salto de fase, até se voltar a carregar na tecla. Cada recomeço cria uma cópia
nova do nível, com um overlay e uma personagem novos, pelo que o estado das ajudas fica guardado
fora deles, em variáveis estáticas do overlay, e cada overlay novo entrega-o à sua personagem. Na
personagem, cada ajuda é uma única variável. O god mode é lido apenas nos pontos por onde entram o
dano e a morte: a perda de SP, a morte e o fim do tempo do agarrão. O noclip é lido nesses mesmos
pontos, na reação aos golpes e no movimento. O resto do jogo não as conhece. O F4 continua a
retirar SP com o god mode ligado, para experimentar a regeneração. As duas teclas estão reservadas
nos perfis de controlos, pelas mesmas razões do F4. Teste: `test_debug_cheats.gd`.

Há três limitações conhecidas, aceites por se tratar de uma ferramenta de depuração. Os espinhos
detetam a personagem quando ela entra neles. Por isso, quem desliga o noclip ou o god mode já
dentro de uma faixa de espinhos só morre quando sair e voltar a entrar. Quem desliga o noclip
dentro de uma parede ou do chão fica entregue à separação de corpos do motor. Os sons e o tremor
da aterragem medem a queda a partir do ponto mais alto do voo, pelo que desligar o noclip junto ao
chão, depois de voar alto, soa como uma queda longa.

Na página dos números do overlay (F3), as teclas 1, 2 e 3 recomeçam o nível no início dessa fase, atrás do
mesmo escurecer de uma morte. No momento do recomeço, o nível (`Level.jump_to_phase`) percorre os
seus pontos de gravação pela ordem da cena, que é a do percurso, marca no GameState os que ficam
para trás e esquece os seguintes, pelo que a cópia nova põe a personagem no ponto dessa fase, como
faria o Continue. A fase 1 começa depois do tutorial. Só mudam os pontos de gravação: as falas, as
ofertas, os upgrades, o crucifixo e o registo moral ficam como estavam, pelo que o estado não é o
de quem jogou até lá. Numa partida, o Main grava esse estado por cima do save, porque um recomeço
volta sempre ao save. Não fazem nada uma fase que o nível não tenha, um nível de uma só fase (como
a sala de treino, onde os números escolhem as estações), o jogo em pausa e a troca de fase. Uma
segunda tecla durante o escurecer não o recomeça e fica a última fase pedida. Estas teclas não
estão reservadas: fora da página dos números são do jogador, e uma tecla que o perfil Custom dê a
uma ação continua a ser só dessa ação, porque a personagem lê as ações enquanto estão premidas.
Um teste verifica que, em cada nível do menu, os pontos que começam uma fase estão por ordem na
cena. Teste: `test_debug_phase_jump.gd`.

Uma linha `run` mostra os números escondidos da partida, que o jogador nunca vê:

- a fase em curso;
- as mortes nessa fase e no nível;
- a zona da última morte;
- o tempo passado na fase;
- a pressão das mortes face ao limiar da próxima oferta do atalho;
- o estado dessa oferta: aberta, à espera numa zona, ou fechada depois de o atalho ser aceite.

Serve para afinar o ritmo das ofertas por mortes a jogar, sem ter de contar as mortes à mão.

O overlay é uma cena própria, `scenes/others/debug/debug_overlay.tscn`, num `CanvasLayer`, pelo que não se
desloca com a câmara. Recebe a personagem pelo Inspector e lê-a, ou fere-a com o F4, sem que ela
dependa dele, pelo que a personagem é testada e exportada sem o overlay. Continua ativo com o jogo
em pausa e, nas exportações de release, remove-se a si próprio, e as teclas de depuração com ele. O
`test_debug_overlay.gd` verifica o comportamento nas versões de depuração. O overlay pergunta ao
Godot se a versão é de depuração (`OS.is_debug_build()`) num método próprio, que o
`test_debug_cheats.gd` substitui para responder como uma versão de release. O teste verifica que,
nesse caso, o overlay se remove antes de ler qualquer tecla e de entregar as ajudas à personagem,
pelo que o F1, o F2 e o F4 não fazem nada, mesmo com as ajudas ligadas antes. Só a primeira
exportação de release confirmará que o `OS.is_debug_build()` devolve falso.

Na sala de teste, uma segunda vista (`scenes/others/debug/demon_debug_view.gd`) desenha sobre cada demónio o
estado em que está e há quanto tempo (em frames de física, que param na pausa, como os tempos dos
estados), e uma seta para onde está virado. Ao longo do chão, desenha o
posto e o troço da ronda. Enquanto o demónio persegue ou procura, marca com uma cruz o último sítio
onde viu a personagem, e enquanto a vê, uma linha até ela. Serve para experimentar e afinar os
estados dos demónios enquanto o retângulo provisório não os mostra, sem mudar o demónio nem os
níveis, que não a têm. Aparece com o overlay, em qualquer das duas páginas, e desaparece quando ele se esconde, e remove-se a si própria
fora das versões de depuração. Para experimentar a procura, a sala tem uma parede de esconderijo no
chão, em x 1700, à esquerda do demónio do chão (x 2400), com 144 px de altura, mais do que a
personagem (96 px) e menos do que o seu salto (240 px). Ficou desse lado porque, mais à direita,
impedia os demónios do chão de chegar aos degraus. O `test_demon_debug_view.gd` verifica a ligação
aos demónios, o F3, o texto do estado (incluindo que os segundos recomeçam a cada estado e param na
pausa) e que a parede esconde a personagem logo atrás dela, mas não à frente.

#### Câmara

A câmara (`scenes/others/camera/game_camera.tscn`, script `GameCamera`) é uma `Camera2D` colocada ao lado
da personagem, na cena do nível, e não dentro da cena da personagem. Recebe a personagem pelo
Inspector e lê-a sem que ela dependa da câmara; o nível pode assim parar a câmara numa cena
cinemática sem alterar a personagem. É processada no passo de física e depois da personagem
(Physics Priority 1), pelo que lê a posição do próprio passo. Os valores estão num `Resource`,
`CameraStats`.

A suavização é feita pelo script, e não pela `Camera2D` (ver "Physics interpolation"). O seguimento
usa uma suavização exponencial, com o peso `1 - exp(-k·Δt)`, e as deslocações da antecipação usam a
solução exata de uma mola criticamente amortecida, que regressa à posição de equilíbrio o mais
depressa possível sem oscilar. Em ambos os casos, o resultado não depende da duração do passo de
física. A personagem emite o sinal `landed`, que a câmara usa para reenquadrar ao aterrar.

A câmara pode enquadrar a personagem de outras formas, para as comparar em playtest (#282). Segue o
padrão Strategy: cada forma alternativa é um nó filho da câmara do tipo `CameraBrain`
(`camera_brain.gd`, uma classe abstrata), que em cada passo de física indica apenas o centro do ecrã e o
zoom. A câmara conserva tudo o resto: as cenas cinemáticas, o tremor, a vibração, o motion blur e o que
se mantém ativo junto ao ecrã. Sem nenhum `CameraBrain` em uso, a câmara executa o código anterior sem
qualquer alteração, o que os testes da câmara já existentes confirmam sem terem sido modificados. Na
troca não há saltos: a forma nova parte da posição e do zoom do ecrã, e o regresso à forma da própria
câmara desliza como no fim de uma cena cinemática, no máximo a 2000 px/s na horizontal. Ficaram de
parte duas alternativas: uma `Camera2D` por forma de enquadramento, que duplicaria o tremor, a
vibração e o feedback (ou os mudaria de nó a cada troca), e a passagem do código atual para um
`CameraBrain`, que alteraria código já validado antes de se saber se a câmara atual se mantém.

A cena da câmara traz uma forma alternativa, a câmara de zoom fixo (nó `Fixed`, script
`FixedFraming`, valores em `FixedFramingStats`). Responde às queixas do playtest de 20/11: rocha a
mais no ecrã, um zoom que muda em fronteiras que o jogador não vê e a personagem fora do centro. O
zoom é sempre 1,4. Na horizontal, a personagem fica centrada; na vertical, fica 12 % da altura do ecrã
abaixo do centro (25 % no #282), porque por baixo do chão só há rocha. Os valores do jogo estão no
`fixed_framing_stats.tres`, mais calmos desde o #284 (ver "Câmara" acima); os do script são os do
#282. O ecrã segue um ponto de foco, que só se
desloca quando a personagem sai de uma zona morta à volta dele: 96 px para cada lado (28 no #282) e, no ar, um
salto completo para cima, pelo que um salto não move o ecrã. No chão, o foco acompanha logo a altura
da personagem. O ecrã aproxima-se do foco com uma mola criticamente amortecida, no máximo a
2000 px/s. Enquanto a personagem arrasta o foco, o ecrã aponta à frente dele a distância a que a mola
fica para trás (2v/ω), pelo que, a uma velocidade constante, o ecrã não fica para trás nem passa à
frente. A correr, o foco vai 3 % da largura do ecrã à frente da personagem (5 % no #282), menos do que
a zona morta, pelo que o ecrã fica um pouco atrás dela; ao fim de 0,35 s de
queda, mais do que dura a descida de um salto completo, mostra mais por baixo dela. Deslizar por uma
parede não conta como queda, para a subida de uma chaminé não fazer o ecrã subir e descer. Com o
corpo no ecrã, mantém-no a pelo menos 10 % do ecrã das bordas. Uma personagem colocada a mais de
200 px num só passo, e não deslocada, é enquadrada nesse mesmo passo. Depois de uma morte ou de um
salto de fase, o nível recomeça numa cópia nova, cuja câmara começa já enquadrada.

Os limites do ecrã vêm do mapa e não de zonas desenhadas. A classe `RockMap`
(`scenes/levels/rock_map.gd`) lê os tiles do nível uma vez: um tile com colisão que não seja de
sentido único é rocha, incluindo as rampas, também quando estão viradas ou rodadas no editor. A
partir da posição da personagem, encontra o espaço aberto ligado a ela, por preenchimento (flood
fill). O ecrã fica dentro da caixa desse espaço, alargada 2 tiles, e dentro dos limites da própria
câmara definidos no nível, que a câmara lhe passa; junto à borda, estes limites prevalecem sobre a
margem de 10 %. Assim, um mapa novo ou alterado não precisa de nada definido à mão. Sem mapa, ou
com o espaço aberto a chegar à borda do mapa, valem só os limites da própria câmara. Numa chaminé, uma
passagem vertical entre rocha com até 6 tiles de largura e pelo menos 6 de altura, o ecrã fica no
eixo dela. A medição usa a mesma `RockMap`, para as duas lerem a rocha da mesma maneira.

A medição (`measure_camera_space.gd`) coloca a personagem em 1462 posições do nível 1, um tile em cada
três de cada chão a que ela chega, e lê o ecrã depois de a câmara assentar. Conta como enchimento a
rocha rodeada de rocha nos 8 lados, porque as pedras da orla cobrem cerca de um tile para dentro da
rocha. As distâncias estão em píxeis de um ecrã de 1920 × 1080. A tabela foi medida a 22/11, no mapa
depois do merge do `dev` e com os valores do #284.

| Medida | Câmara das zonas | Câmara de zoom fixo |
|---|---|---|
| Enchimento do ecrã, média | 35,3 % | 37,5 % |
| Enchimento do ecrã, 90.º percentil | 53,7 % | 55,6 % |
| Distância da personagem ao centro, na horizontal (média; 90.º percentil) | 188 px; 490 px | 114 px; 134 px |
| Distância da personagem ao centro, na vertical (média; 90.º percentil) | 223 px; 362 px | 135 px; 133 px |
| Zoom | de 1,00 a 2,28 (1,30 em 53 % das posições) | 1,40 em todas |
| Mudanças de zoom por 100 tiles percorridos | 2,6 | 0 |

Na vertical, a câmara de zoom fixo deixa a personagem abaixo do centro de propósito: 12 % de 1080 px
são 130 px. Os 134 px na horizontal são a borda da zona morta (96 px do mundo), à escala do zoom.
Com o homem mais acima do que no #282, o ecrã mostra mais do chão, que é rocha: o enchimento médio
fica 2,2 pontos acima do das zonas. No #282, com 25 % abaixo do centro e no mapa de então, ficava 0,1
pontos acima (34,9 % contra 34,8 %). É o custo de ver mais por baixo nas descidas, pedido no
playtest de 22/11. Na comparação de zooms, com a personagem 25 % abaixo do centro, o 1,5 ficava
abaixo das zonas, mas mostra menos à volta da personagem (26,7 × 15,0 tiles, contra 28,6 × 16,1 a
1,4).

A câmara de zoom fixo lê o mapa quando começa num nível: na primeira troca para ela e, se estiver
escolhida, no primeiro frame de cada cópia nova do nível, depois de uma morte ou de um salto de fase.
No nível 1 (373 × 381 tiles), a troca demora entre 88,5 e 89,7 ms (duas execuções da medição), um
atraso de cinco ou seis frames. Como o nível 1 começa com esta câmara desde o #284, a leitura repete-se
em cada recomeço: uma cópia nova do nível 1 leva de 555 a 571 ms a criar e a arrancar, contra 460 a
482 ms com as zonas (três execuções alternadas). Esse frame cai com a íris da morte fechada, pelo que
o ecrã preto dura cerca de 0,1 s mais. Ler o mapa uma vez por nível, e não por cópia, fica para depois.

Ficaram de parte um zoom fixo com a personagem centrada também na vertical (40,3 % de enchimento a
1,3), porque a metade de baixo do ecrã fica sob o chão, e um ecrã preso ao chão e ao teto (33,9 % a
1,4), porque a altura da personagem no ecrã variava de sítio para sítio, como com as zonas. Depois do
playtest de 22/11, o nível 1 passou a começar com a câmara de zoom fixo (#284).

As zonas (`CameraZone`, uma `Area2D` na camada `camera_bounds`) são lidas pela geometria das suas
formas retangulares, com a transformação completa (uma zona escalada tem o retângulo que o editor
mostra), e não por sinais de física, cuja ordem não é controlada. As formas desativadas não contam, e
uma forma rodada é ignorada com um erro. A câmara limita ao intervalo que a zona permite o ponto para
onde se dirige e também a posição final: o seguimento e a antecipação atrasam-se cada um em relação
ao seu alvo, e sem este segundo limite a soma ultrapassava a borda em até 120 px. A antecipação
conta a partir do foco, e não do ponto onde o limite segura o ecrã: junto a uma borda, o limite já
afasta o ecrã da personagem, e uma antecipação somada a esse ponto podia deixar a personagem fora do
ecrã, até ao valor da Look Ahead Distance, enquanto não recuasse o Turn Threshold. Ao mudar de zona,
o seguimento passa a ser uma mola criticamente amortecida (Zone Change Sharpness), com a mesma
solução exata da antecipação, que parte da velocidade que a câmara já tinha, para não travar uma
câmara em movimento, por exemplo numa queda; cada passo fica ainda limitado pela Zone Change Speed,
e a passagem termina quando a câmara está a menos de 0,5 px do destino. Limitada a essa velocidade,
a mola só começa a travar a 2 × velocidade / Zone Change Sharpness do fim, o que basta para não
ultrapassar o destino. A caixa de uma zona desce a sua margem inferior (`bottom_margin`), ocupa na
horizontal toda a largura dos limites da própria câmara se a zona tiver `limit_horizontally`
desligado, e fica dentro desses limites, que o motor também aplica ao ecrã. Quando a caixa da zona é
mais baixa do que o ecrã, o intervalo vertical reduz-se a um ponto, obtido por interpolação linear,
segundo a `vertical_anchor` da zona, entre o ecrã encostado ao topo da caixa (0) e o ecrã encostado
ao fundo (1). Fora das zonas, e na horizontal, esse ponto é o centro da caixa, como nos limites da
própria `Camera2D`. Num ponto que está em várias zonas, a câmara escolhe aquela em que os pés da
personagem entraram por último, contando os passos de física; entre zonas em que entraram no mesmo
passo, a de menor área, a soma dos seus retângulos. A câmara considera as zonas
que estão dentro da cena do seu nível, incluindo as de subcenas, e ignora as que estão sob um nó a
ser removido, o que evita usar as zonas de um nível a ser descarregado; se existirem zonas mas
nenhuma pertencer ao seu nível, emite um aviso.

O zoom segue o mesmo tipo de mola, com a Zoom Sharpness, até ao zoom da própria câmara multiplicado
pelo zoom da zona e, com a personagem parada há Idle Delay, pelo Idle Zoom. Numa zona com
`fit_height`, o zoom da zona é a altura do ecrã a dividir pela altura da caixa da zona mais a margem
inferior e a Fit Headroom, entre 1 e a Max Zone Zoom. Com `auto_zoom` e os tiles do nível na câmara
(`level_tiles`), a câmara percorre, em cada coluna da zona, os tiles de baixo para cima a partir do
ar da própria zona: a primeira célula de ar fora da zona que surge depois de rocha é outra passagem,
e ar fora da zona logo a seguir ao ar da zona é uma abertura, que não conta. Com a âncora vertical a,
um ecrã mais alto do que a zona (com a margem) sobe a × a diferença acima do topo da zona; o zoom é o
necessário para o topo do ecrã não passar do fundo da passagem mais baixa, entre 1 e a Max Zone
Zoom, e o zoom definido na zona é o mínimo. A posição dessa passagem lê-se uma vez por zona. A personagem conta como
parada quando está no chão, não pede corrida e se move a menos de 1 px/s; nesse caso a antecipação
horizontal vai para zero. A antecipação e o olhar para baixo são divididos pelo zoom, para ocuparem
sempre a mesma fração do ecrã, e o intervalo do centro do ecrã usa o zoom atual, como os limites da
`Camera2D`.

Os testes `test_game_camera.gd`, `test_camera_window.gd`, `test_camera_look_ahead.gd`,
`test_camera_vertical.gd`, `test_camera_zones.gd`, `test_camera_zoom.gd` e `test_landed_signal.gd` verificam estes
comportamentos. O `test_camera_keeps_player_on_screen.gd` verifica que, numa sala com uma só zona, o
corpo da personagem fica inteiro no ecrã: junto às duas paredes, numa queda junto ao teto e em jogo
com comandos aleatórios, sempre os mesmos em cada execução, que tem de chegar perto das duas paredes.
Com várias zonas há dois casos conhecidos em que o corpo sai do ecrã, ambos anteriores a esta
correção: na passagem entre duas zonas encostadas sem parede, até 16 px durante 2 passos, e com os pés
logo abaixo do limite superior de uma zona com outra por cima, até 86 px, porque a zona se escolhe pela
posição dos pés. Sem janela, o Godot cria uma janela de 64 × 64 px, e o
modo de proporção Expand transforma-a num ecrã de 1920 × 1920; por isso, os testes da câmara fixam o
ecrã em 1920 × 1080 antes de começar.

O tremor do ecrã não altera a posição da câmara. Um nó filho, `CameraShake`, desloca o `offset` da
`Camera2D`, que o seguimento, as zonas e os limites não usam, pelo que nenhum deles o vê. As regras
estão numa classe sem nó, `ShakeTrauma`, que os testes executam diretamente: cada impacto soma
trauma, até 1, ou, nos toques para se soltar e na libertação, leva-o a um nível fixo sem o somar, e
o trauma desce a uma taxa constante; o tremor é o trauma elevado a um expoente, e o desvio
segue um ruído Simplex contínuo, com cada eixo numa linha diferente do ruído. O desvio é dividido
pelo zoom, para mover o ecrã os mesmos píxeis com qualquer zoom, e calcula-se em cada frame
desenhado, porque só altera o que se vê: custa 1,1 µs por frame sem tremor e 1,9 µs com o trauma
no máximo, 0,011 % de um frame a 60 FPS (`measure_camera_shake.gd`, três execuções, 2026-11-14).
Com o jogo em pausa, a câmara para e, com a interpolação de física, continuaria a desenhar o último
desvio; por isso, ao entrar na pausa, o desvio volta a 0 e a câmara redesenha logo. Os demónios
decidem se estão no ecrã pela posição da câmara, com o zoom e os limites, sem o desvio, pelo que o
tremor não os faz parar nem arrancar. Não o decidem pelo que está desenhado, porque, com a
interpolação de física, o desenho segue a câmara com até dois passos de física de atraso, desvio
incluído: medido com um demónio a 1 px da borda do ecrã, com o tremor no máximo, a leitura pelo
desenho errava em 58 de 60 passos e a leitura pela posição em nenhum. Os momentos que fazem tremer o ecrã são ligados por outro nó filho da câmara,
`ImpactFeedback`, que procura entre os filhos da personagem o `Hurtbox`, o `GrabEscape`, o
`Crucifix` e o `PlayerSounds`, e no nível os `Hazard`, os `LethalSpikes` e as `FallingRock`, e liga-se aos sinais que
estes já emitem, sem que nenhum dependa do tremor. Faz a procura no fim do primeiro frame do nível,
depois de o nível ter tirado o crucifixo a quem já o perdeu, para esse passo não contar como um
impacto. Ficou de fora um deslocamento aleatório com um `Tween` por impacto: cada impacto teria o seu
`Tween` a mexer no mesmo `offset`, impactos seguidos disputavam-no e o pior caso não tinha teto; o
trauma tem um dono só e nunca passa de 1. O `test_camera_shake.gd` verifica as regras (o trauma
máximo acaba em meio segundo e o Speed tem a rapidez que o Inspector descreve), a opção e o ecrã das
opções, o trauma de cada momento, o zoom, a pausa, o início de um nível sem crucifixo e os
demónios, e que a morte da personagem faz tremer o ecrã sem mover a câmara.

A vibração do comando segue o mesmo desenho. O `ImpactFeedback` responde a cada momento e a cada
estado que o corpo da personagem sente com um pedido a outro nó filho da câmara, `ControllerRumble`,
e, nos golpes e nos momentos graves, também com trauma para o `CameraShake`. A lista dos momentos
fica assim num só sítio, e o tremor e a vibração não se desencontram. Os valores estão num recurso
próprio, `RumbleStats`, agrupado pelos degraus da escada; cada impulso é um `RumblePulse` e cada
estado contínuo um `RumbleSustain`. As regras estão numa classe sem nó, `RumbleRules`. Cada impulso
tem um nível para cada motor, uma duração e uma descida final em linha reta. Cada vibração contínua
tem os seus níveis e uma pulsação em cosseno. Com vários ao mesmo tempo, cada motor fica no nível do
mais forte, limitado ao intervalo de 0 a 1, o que o Godot aceita. Uma vibração contínua desce à sua
parte só nos motores que um impulso usa, em proporção do que resta do impulso, e por isso volta sem
salto quando ele acaba. O primeiro frame de um impulso não lhe desconta tempo, para que dure
o tempo todo a qualquer taxa de frames. O `ControllerRumble` volta a pedir ao comando quando esse
resultado muda e sempre que começa um impulso, porque um impulso igual a outro que já corre acaba
mais tarde. Cada pedido vale pela duração do impulso que acaba por último ou, com vibração contínua,
por 0,25 s, renovados antes de acabarem, para que os motores parem sozinhos mesmo que o jogo deixe de
correr. A pausa e a janela fora de foco descartam os impulsos, mas guardam as vibrações contínuas,
que voltam com o jogo.
O comando ativo é o do último input: um botão, ou um analógico movido pelo menos até meio, torna esse
comando o ativo, e uma tecla ou um botão do rato deixam o jogo sem comando ativo. É partilhado por
todas as instâncias do nó e passa de um nível para o seguinte: o Godot só envia eventos do analógico
quando o valor muda, e quem entra na fase seguinte com o analógico encostado não os voltaria a dar.
Cada instância guarda o comando a que fez o último pedido e, quando o comando ativo muda, para esse e
passa a sua vibração para o novo. Assim, o nó do nível e as amostras das opções, que estão na árvore
ao mesmo tempo, não dependem da ordem em que recebem o input. A amostra vibra o último comando usado
mesmo com o rato em uso (Keeps Last Controller), para que um arrasto do slider se sinta no comando.
Com a janela fora de foco nenhum impulso começa, também onde o jogo não
pausa (na mudança de fase ou num nível corrido com F6). O `_process` só corre enquanto algo vibra. No
pior caso, com três impulsos a descer e duas vibrações contínuas a pulsar, pede ao comando em todos
os frames e custa cerca de 4,4 µs por frame, 0,026 % de um frame a 60 FPS. O `_input` vê cada evento
de input, haja vibração ou não, e custa cerca de 0,7 µs por evento; iniciar e parar um impulso custa
cerca de 4,9 µs (`measure_controller_rumble.gd`, três execuções, 2026-11-14). O `ImpactFeedback` só tem
`_process` com o crucifixo erguido. A aterragem cresce com a altura da queda, que o `PlayerSounds` já
mede para escolher o som, e não com a velocidade, porque a queda chega à velocidade máxima aos
166 px. A personagem passou a dar dois sinais, `head_bumped` e `got_on_wall`, emitidos uma vez por
contacto, como o `landed`. Os picos letais matam sem sinal próprio: chamam a morte da personagem. O
`ImpactFeedback` ouve a entrada de um corpo nos picos e reconhece a morte nos picos quando essa
entrada e a morte caem no mesmo passo de física, por qualquer ordem, sem mudar o script dos picos. A
vibração contínua do crucifixo lê o aviso do próprio crucifixo, o mesmo que a luz segue. Depois da
morte, o crucifixo fica erguido até a sala recomeçar, e o `ImpactFeedback` deixa de responder ao que
ele diz. Ficaram de fora três alternativas: derivar a vibração do trauma do tremor,
que dava a todos os momentos a mesma mistura de motores e fundia os toques rápidos do agarrão num
zumbido; um segundo nó a ouvir os mesmos sinais por conta própria, que duplicava a procura dos
momentos; e impulsos de força constante, que se sentem como um zumbido e não como uma pancada
(ADR 0062). O `test_controller_rumble.gd` verifica as regras, o comando escolhido e o que passa ao
nível seguinte, dois nós ao mesmo tempo, os pedidos renovados e os que não se repetem, a vibração
contínua com as paragens e o foco, as duas opções, um ficheiro de opções com valores errados e o ecrã
das opções com a amostra, com um arrasto real do rato e com o ecrã fechado a meio do arrasto. O
`test_rumble_moments.gd` verifica a escada sobre os valores do jogo, o impulso de cada momento, a
vibração contínua do agarrão e do crucifixo, os toques num agarrão real, a morte com o crucifixo
erguido, o crucifixo a esgotar-se, o que entra na luz dele (nada com ele em baixo, uma só pancada
ao erguê-lo por cima de duas almas e outra quando voltam a entrar juntas, nenhuma para o
desbloqueador de um portão), o crucifixo depois da morte, a morte nos picos letais (pelas duas
ordens, e sem picada se a entrada vier noutro passo), a aterragem pela altura da queda e os tiques
dos movimentos reais (salto, aterragem, cabeça no teto, mesmo encostada vários
frames, e parede), com a física do jogo.

#### Fundo em camadas

O fundo é feito de nós `BackgroundLayer` (`scenes/levels/background/background_layer.gd`), uma extensão do
`Parallax2D` do Godot, um por camada. O `Parallax2D` desloca a camada uma fração (Scroll Scale) do
movimento da câmara; a extensão acrescenta-lhe o que todas as camadas do jogo precisam:

- O modo de cobertura (Cover). Em FIT, a imagem é ampliada, sem deformar, até ao tamanho do ecrã
  somado ao percurso da camada (o percurso da câmara dentro dos seus limites, menos o ecrã, vezes a
  Scroll Scale), e começa no limite superior esquerdo da câmara. Na sala de teste (5824 × 2244 px), a
  0,25, uma imagem de 1920 × 1080 é ampliada 1,508 vezes em 16:9 e 1,743 vezes em 21:9. Em REPEAT, a
  imagem é ampliada até ao tamanho do ecrã, se for menor, e repete-se de imagem em imagem; o Repeat
  Size do Godot ignora a escala, pelo que recebe o tamanho já ampliado. Em NONE, as peças ficam onde
  foram colocadas. O cálculo repete-se quando a janela muda de tamanho e quando a Scroll Scale, o
  modo, a câmara ou os limites da câmara mudam, também com o jogo a correr; enquanto não houver
  câmara, a camada espera por ela. Em FIT e em REPEAT, a camada controla a posição, a escala e o
  Centered da imagem e o seu próprio Repeat Size, e, em FIT, também o Scroll Offset: estes campos não
  se acertam à mão.
- A rampa de cor de cada camada (Ramp e Reverse Ramp). A camada cria um único material com o shader
  `scenes/others/shaders/color_ramp.gdshader` e atribui-o a todas as peças sem material próprio, incluindo as
  que entram depois; mudar a rampa muda todas as peças de uma vez, e retirá-la devolve-lhes as cores
  originais.

O shader lê o cinzento de cada píxel e procura a cor correspondente na rampa; a cor do vértice, que
traz o Modulate do nó, tinge o resultado, e o alfa da imagem mantém-se. Estes comportamentos só se
observam com o renderer a desenhar, pelo que foram medidos numa janela, com o renderer Compatibility:
um cinzento de 0,02 toma a cor da ponta direita da rampa (98 % dessa cor), um de 0,98 a da esquerda, um píxel
transparente deixa ver o que está atrás, e um Modulate de 50 % reduz a cor a metade (0,49).

Ficaram de fora três alternativas. Repetir a imagem atual, que não foi pintada para se repetir,
deixaria as juntas visíveis. Um fundo parado não dá profundidade. Descrever o fundo num `Resource` e
construí-lo ao arrancar combinaria com o modelo de nível previsto, mas as peças deixariam de se ver e
posicionar no editor. O modelo `level_background.tscn` fixa as quatro camadas e as suas distâncias, e
o fundo de cada nível herda-o (`test_room_background.tscn`, na sala de teste).

O `Parallax2D` tem a physics interpolation desligada por omissão, porque segue a câmara, que já é
interpolada. O modo FIT supõe uma câmara sem zoom, como a do jogo. O `test_background_layer.gd`
verifica a cobertura nos quatro cantos dos limites e no centro, em 16:9 e em 21:9, a espera por uma
câmara que chega depois da camada, a nova cobertura quando os limites da câmara crescem, a
repetição, a rampa e a estrutura do modelo.

A ordem de desenho segue uma convenção única, para que nenhuma peça fique por baixo ou por cima de
outra por acaso:

| Ordem | O que se desenha | Como |
|---|---|---|
| 1 | camadas Far, Middle e Near do fundo | primeiro nó da cena do nível, com Z Index 0 |
| 2 | plano de jogo: portões, personagem, demónios, picos, tiles e as outras peças, por esta ordem | nós seguintes do nível, com Z Index 0 (os picos com 1) |
| 3 | camada Front do fundo | Z Index 10 |
| 4 | interface e overlay de depuração | `CanvasLayer`, por cima de tudo |

No plano de jogo, os tiles vêm depois da personagem e dos demónios, para que a rocha tape a parte
da arte que passa do corpo, como a cauda de um cão encostado a uma parede (#271). A personagem vem
antes dos demónios, porque estes se movem depois dela em cada passo de física (a mordida nas costas
conta com isso). Um demónio que avisa, investe ou agarra sobe para Z Index 1, para ficar por cima
da personagem e dos outros demónios. A iluminação do nível 1 põe a rocha também em 1, e com o mesmo
Z Index vale a ordem dos nós, por isso esse demónio continua por baixo da rocha; sem a iluminação, a
rocha fica em 0 e ele passa por cima dela. Os picos vêm logo antes dos tiles (#284): com a
iluminação, ficam por baixo da rocha e das pedras da orla e por cima da cópia da rocha que dá
profundidade, como a personagem e os fogos, e nascem entre as pedras em vez de as taparem. As pedras
da orla saem 20,4 px da rocha e escondem a metade de baixo dos 40 px dos dentes. Os picos continuam
em Z Index 1, por cima da personagem, que na morte nas silvas é puxada para dentro delas. O
`test_dogs_behind_rock.gd` verifica a ordem com a iluminação, que a marca de alerta continua por cima
da rocha e que os picos ficam por baixo dela.

Os fogos do nível 1 ficam 12 px abaixo do topo da rocha (`FIRE_SINK`, no `lighting_rig.gd`, #284).
As chamas afinam na base, e a fogueira só chega à largura toda 10,8 px acima do fundo do desenho;
pousadas no topo da rocha, essa ponta fina via-se por cima das pedras e o fogo parecia flutuar.
O `test_fires_seated.gd` verifica que cada um dos 87 fogos está sobre rocha, com ar por cima, entre
10,8 px e 20,4 px abaixo do topo (medido: 12,0 px em todos).

#### Linha de vista: um componente por objeto

Cada cão e cada faixa de picos tem um nó `SightReveal` (`scenes/others/sight/`). De três em três
passos de física, com os componentes repartidos pelos três passos, o nó lança raios dos olhos da
personagem (o nó `Eyes`, script `SightEyes`) até três filas de pontos na caixa do elemento, do topo
à base (Rows), com os pontos de cada fila espaçados no máximo 96 px, contra a camada world. Para de
lançar quando a personagem vê metade dos pontos (Full Share); com menos, passa a fração vista à
regra, que desenha o elemento em parte. Um raio que encontra o corpo de uma personagem (um
`CharacterBody2D`) segue para lá dele, até quatro corpos por raio; o resto da camada world para-o.
A menos de 96 px dos olhos (Near Radius), o elemento conta como visto sem lançar raios. Antes dos
raios, o componente vê se a caixa está no ecrã, com a margem: os olhos calculam o
retângulo do ecrã uma vez por passo, e o que está fora não lança raios. Nos cães, o componente
pergunta também aos sentidos do cão (`DemonSenses.can_see`), e o sinal `warning_started` do cão
desenha-o por inteiro de imediato (`reveal_now`): assim, um cão que vê a personagem ou começa um
ataque está sempre visível. As regras (a memória dos picos, o tempo antes de esconder, as transições
e a opção) estão numa classe pura, `RevealRule`, verificada pelo `test_reveal_rule.gd`; o
`test_sight_reveal.gd` verifica o componente em cena. Os olhos registam-se numa variável estática ao
entrar na árvore, para que nenhum elemento procure a personagem em cada verificação. Sem olhos na
árvore, como numa cena aberta com F6, tudo se desenha, mas nada conta como visto.

A alternativa considerada foi uma máscara recortada pelo polígono de visibilidade da personagem,
calculado em cada frame com o varrimento angular descrito pela
[Red Blob Games](https://www.redblobgames.com/articles/visibility/). Dava um recorte exato ao píxel,
mas obrigava a extrair os segmentos de toda a geometria do nível e a reorganizar as cenas dos níveis
para pôr os elementos escondidos sob a máscara. Ficou de lado por esse custo e esse risco. Pode
entrar mais tarde como acabamento visual, mantendo a regra de jogo deste componente. Uma luz 2D
invisível com sombras faria o mesmo na placa gráfica, mas misturava-se com o sistema de luz previsto.

Custo (`measure_sight_reveal.gd`, duas execuções, 2026-11-16). O nível 1 tem 171 componentes (99
cães e 72 faixas de picos). Com a personagem no início do nível, antes do corte fora do ecrã, os
componentes acrescentavam em média cerca de 2,0 ms por frame aos scripts de física e 0,4 ms aos de
desenho, acima dos 2 ms que um sistema pode gastar. Com o corte, e escrevendo a opacidade só quando
muda, acrescentam até 0,14 ms aos scripts de física (numa das execuções, a diferença ficou dentro do
ruído) e 0,16 a 0,25 ms aos de desenho. Sem câmara, que é o pior caso, todos olham: com 40 elementos
escondidos atrás de uma parede (20 cães e 20 faixas de picos de quatro tiles), cerca de 0,26 ms e
0,05 ms; com 200, cerca de 2,4 ms e 0,3 ms; com 40 cães à vista, 0,17 ms e 0,06 ms. Os 200
escondidos passam os 2 ms porque um elemento escondido lança um raio por cada ponto das três filas;
com a fila única da primeira versão, eram cerca de 0,9 ms. Este caso não acontece no jogo: o nível 1
tem 171 elementos no total e, com o corte fora do ecrã, só lançam raios os que estão no ecrã. Se
um nível se aproximar dele, baixar o Rows para 2 ou 1 reduz na mesma proporção os raios dos
escondidos. Os picos já vistos não custam nada, porque deixam de verificar. O pior frame variou
muito entre execuções, pelo que só as médias são citadas.

#### Menus, pausa e opções

A cena principal fica carregada durante todo o jogo e contém o menu principal, o menu de pausa e um
nó `LevelSlot`, onde entra o nível escolhido. Os menus apenas emitem sinais; é o `main.gd` que decide
o que fazer. Por isso, um nível não precisa de incluir menus nem pausa.

Cada fase de um nível é uma cena própria, com a sua personagem e a sua câmara, e só a fase em curso
está carregada. A passagem para a fase seguinte faz-se por uma área `PhaseExit`, que indica apenas o
caminho do ficheiro da fase seguinte, e não a cena, para que carregar uma fase não carregue também a
seguinte. Quando a personagem entra nessa área, o Main escurece o ecrã em 0,25 s
(Main › Fade Time), congela a fase, carrega a seguinte noutro thread e, com o ecrã preto, troca uma
pela outra e volta a clarear. As duas fases do nível 1 levaram, em conjunto, cerca de 0,1 s a
carregar (medido a 2026-10-19), pelo que o carregamento termina antes de o ecrã ficar preto. Durante
a passagem, o Esc não pausa. Uma fase aberta com F6 não tem o Main: a porta muda de cena diretamente,
sem escurecer. O `test_phase_exit.gd` verifica as duas situações. Uma `PhaseExit` sem fase seguinte é
o fim do nível: o Main escurece o ecrã e volta ao menu principal (no nível 1, só depois das últimas
falas da Asmodeu).

A pausa usa `get_tree().paused`. O Main corre sempre (Process Mode Always) e só o `LevelSlot` é
Pausable: o nível para e o Main continua a receber o Esc. O overlay de depuração continua ativo, e o
mesmo acontece a qualquer nó de um nível com Process Mode Always. Perder o foco da janela também pausa
(Main › Pause On Focus Loss), opção que convém desligar quando se afinam valores pelo separador
Remote do editor.

Na pausa, um véu preto a 90 % (`MenuBackdrop` › Background Alpha) cobre o nível, que continua a
ver-se por baixo (#284; era 60 %, depois 80 %). A música dos menus (`MenuMusic`) entra quando a pausa abre e sai
quando fecha, em 1,5 s de cada vez. O ouvido sente o volume em decibéis e não no ganho: subir o ganho
em linha reta trazia quase todo o volume nos primeiros instantes e tirava-o de repente no fim. Por
isso a subida e a descida seguem uma curva cúbica (Fade Curve), lenta ao começar a subir e rápida ao
começar a descer: fica mais perto de uma variação regular do volume, sem a espera em silêncio de uma
rampa em decibéis a partir de −80 dB. O `test_menu_music_fade.gd` mediu, a meio de cada fade, 0,125 do ganho (−18 dB),
contra 0,500 (−6 dB) da linha reta.

O Espaço e o A servem para saltar e para confirmar nos menus, e o B para voltar. Os
botões do Godot disparam quando a tecla é largada, e o B fecha a pausa também ao ser largado. Isso
não chega: num toque rápido, carregar e largar chegam no mesmo frame, e o Godot considera a ação
acabada de carregar durante todo esse frame. Por isso o jogo retoma no frame seguinte ao da tecla que
o retomou. Os testes confirmam que retomar com o Espaço, o A ou o B, também num toque rápido, não faz
saltar nem interagir; com o jogo a retomar no próprio frame, a personagem saltava.

As opções (volume dos buses Master, Music, SFX, Ambience e UI, ecrã inteiro, V-Sync, limite de FPS,
força do tremor do ecrã, força da vibração do comando, vibração contínua, manter o salto para se
soltar do agarrão, mostrar o que a personagem não vê e controlos)
estão no autoload `Settings`, porque têm de estar aplicadas antes de qualquer
cena. Gravam-se em `user://settings.cfg` (no Windows, `%APPDATA%\Godot\app_userdata\P2D\`), um
ficheiro de texto legível, com número de versão. Um ficheiro em falta ou ilegível, ou com valores de
tipo errado ou que não são números, dá os valores predefinidos; um volume, ou uma força do tremor
ou da vibração, fora do intervalo fica no limite mais próximo, e um limite de FPS que não está na lista dá o
predefinido. Uma opção nova entra como chave nova: um ficheiro antigo, que não a tem, dá o valor
predefinido e mantém as outras. Por isso, as cinco opções de acessibilidade entraram sem mudar o
número de versão, que só terá de subir quando uma chave mudar de sentido, de tipo ou de secção. O
limite de FPS só
limita o desenho; a física mantém-se nos 60 passos por segundo. O volume de cada bus no
`default_bus_layout.tres`, acertado no painel Audio do editor, é a mistura do jogo; a opção de volume
escala-a, pelo que 100 % deixa o bus na mistura e 50 % põe-no 6 dB abaixo. O `Settings` lê a mistura
do ficheiro, e não do AudioServer, porque este já pode ter sido mudado por outro nó de opções. Antes,
a opção substituía o volume do bus, e o que se acertava no painel Audio não chegava ao jogo: o
Ambience, a −8,24 dB no ficheiro, tocava a 0 dB. Os menus nunca alteram o áudio, a
janela ou o motor diretamente: pedem a mudança ao `Settings`, que a aplica e grava. Com o jogo
embutido no editor, o ecrã inteiro não se aplica (só a janela normal é suportada); experimenta-se com
o jogo numa janela à parte ou numa exportação.

#### Aspeto dos menus

O menu principal e a pausa seguem a maqueta do grupo: fundo preto, a personagem principal à
esquerda, iluminada por uma luz que entra pelo canto superior direito, e as opções à direita, em
maiúsculas, com uma cruz de cada lado da opção selecionada. A pausa tem a mesma composição, mas o
preto fica a 60 % de opacidade, para se continuar a ver o jogo por trás. As opções e os controlos
abrem na mesma coluna, com o mesmo estilo. As opções abrem num ecrã com quatro separadores em linha
(Audio, Display, Controls e Accessibility), com o primeiro já escolhido, para o jogador nunca ver
todas as opções de uma vez. As setas ou o D-pad percorrem os separadores, que dão a volta do último
ao primeiro, e a página muda de imediato; a seta para baixo, ou o Enter, entra na página. O
separador escolhido fica a branco e sublinhado, e a área das páginas tem a altura da maior, para o
ecrã não saltar ao trocar de separador. A seleção é marcada por uma faixa clara atrás da linha, do
separador ou do botão, que desliza para a nova seleção. A faixa tem uma barra clara de 3 px à
esquerda: medida num frame gravado, a barra tem um contraste de 17:1 com o fundo, enquanto a faixa
sozinha fica em 1,6:1 (o tema `OptionsRowHighlight`). A barra cumpre assim o contraste de 3:1 que o
critério 1.4.11 das WCAG 2.2 (nível AA) pede aos indicadores de foco. O critério 2.4.13 (nível AAA),
que pede também uma área mínima à volta do elemento, não foi o objetivo. Neste ecrã a faixa substitui as cruzes do
menu principal, para haver uma só marca de seleção, também nas linhas de três colunas. O rato por
cima de um separador não o escolhe, para não trocar de página a caminho de uma opção; o separador
escolhe-se com um clique. Por baixo das
páginas, uma linha explica a opção selecionada. Reset to defaults e Back ficam numa barra à parte,
em baixo e em letra mais pequena, com a tecla do Back à frente, a do aparelho usado por último
(Escape no teclado, B no comando; `test_options_back_key.gd`). O Escape é uma tecla reservada, que
o ecrã dos controlos não oferece, e por isso a tecla mostra-o pelo nome dele. O Esc ou o B fecham as
opções a partir de qualquer separador.

- **Fundo partilhado** (`scenes/screens/menu_backdrop.tscn`): o preto (Background Alpha), os raios
  de luz e a personagem. Os raios são um shader (`scenes/others/shaders/god_rays.gdshader`), somado
  ao que está por trás, que ondula lentamente; a cor, a intensidade, a direção, o alcance e o brilho
  junto à origem afinam-se no material do nó Rays.
- **Personagem:** desenhada pelo grupo já com a luz e as sombras pintadas
  (`assets/sprites/menu/menu_character.png`). O
  `scenes/screens/builders/build_menu_art.gd` traz a personagem e a cruz para o projeto, recortadas.
  O ecrã nunca está parado: a personagem respira (cresce 0,6 % a partir dos pés, a cada 4,2 s) e
  afunda até 8 px a cada 6,5 s; os dois períodos não são múltiplos um do outro, para o olho não
  apanhar a repetição. Um fogo por baixo, à esquerda, ilumina-a de baixo e solta fumo em três camadas
  e brasas em quatro (`scenes/screens/menu_embers.gd`: faíscas, cinza e discos desfocados junto à
  lente). Uma só chama comanda a luz, o brilho, o fumo e as brasas, com uma oscilação lenta, de até
  30 % da luz do fogo, e uma rápida, de 3 %. Com as opções
  abertas, a personagem recua para a esquerda e escurece, e cada camada do fogo recua com a sua
  profundidade (as de trás menos, as da frente mais), o que dá relevo à cena. Tudo se afina no
  Inspector do nó MenuBackdrop (grupos Idle, Fire, Recede, Depth e Rays) e de cada camada de brasas.
  Medido a 18/11 no PC do Joaquim: as brasas custam 0,34 ms de CPU por frame e o fundo inteiro 0,73 a
  0,78 ms de GPU. Medido a 19/11 em 10 s de menu gravado, com as regras de flashes das WCAG 2.2
  (`tools/accessibility/wcag_flashes.py`, que diz também como gravar os frames):
  cada brasa pode piscar num píxel, mas só 0,05 % do ecrã passa de 3 flashes por segundo (cerca de
  1100 px a 1920 × 1080). O limite são 21 824 px, 25 % de um campo de visão de 10° num ecrã de
  1024 × 768 ([técnica G176 da W3C](https://www.w3.org/WAI/WCAG22/Techniques/general/G176)). Não há
  flashes vermelhos, porque nenhum píxel chega a vermelho saturado.
- **Sons e vibração** (`scenes/screens/menu_feedback.gd`, um nó por menu): um clique ao mudar de
  opção, um golpe ao escolher e um som surdo ao voltar, cada um com um impulso no comando em uso. Um
  interruptor e uma lista fazem um clique próprio; dentro de uma lista, mudar de item faz o clique,
  escolher faz o golpe e fechar sem escolher faz o som de voltar. Uma tecla aceite ao remapear faz o
  golpe, e o Esc que cancela a espera faz o som de voltar. Uma tecla ou o comando recusados fazem o
  som de recusa: dois golpes surdos, o segundo mais grave, 230 ms ao todo. Distingue-se do som
  de voltar pelo número de golpes e não só pela altura, porque cada som se ouve sozinho, sem o outro
  ao lado para comparar, e porque um tom ainda mais grave sairia da gama que as colunas de um
  portátil conseguem tocar. Num diálogo, como a pergunta antes de um
  jogo novo por cima de uma gravação, só a resposta soa: o No dá apenas o som de voltar. O Quit
  escurece o ecrã durante um tempo próprio (Main › Quit Fade Time, 0,25 s) e só depois fecha o jogo,
  para o golpe se ouvir e a janela fechar a partir do preto e não do menu aceso; os números da
  partida gravam-se antes do fade. Esse tempo é separado do das fases (Main › Fade Time), para um
  fade de fase mais lento ou mais rápido não mudar o Quit, e não desce abaixo de 0,15 s, porque a
  variante mais longa do golpe dura 140 ms e o fecho não a pode cortar (o `test_main_flow.gd`
  verifica-o). O clique e o golpe sorteiam entre variantes sem repetir a anterior
  (`AudioStreamRandomizer`), para uma série de cliques não soar a máquina. A seleção que o próprio
  jogo muda (um ecrã a abrir) não faz som: só conta a que vem até 150 ms depois de uma tecla do
  jogador. Dois cliques ficam a pelo menos 35 ms um do outro, para uma lista percorrida depressa não
  virar um zumbido. A mistura está nos ficheiros: o
  `tools/audio/make_menu_sounds.py` corta, filtra e põe cada som à intensidade do seu evento (o
  máximo de 50 ms de RMS: mudar −27 dBFS, escolher −18, voltar −22, recusa −23, barra −29,
  interruptor −25, que fica em −27,5 porque o pico não passa de −1 dBFS), e todos os volumes da cena
  ficam a 0 dB. Assim o
  clique fica 9 dB abaixo do golpe. O script reproduz os ficheiros do repositório byte a byte. Se
  faltar um som na cena, o jogo usa um feito em código (`menu_sound_synth.gd`), com a sua própria
  mistura: o clique 11 dB abaixo do golpe.
- **Respostas das falas** (#284, `test_wheel_feedback.gd`): a roda das respostas do balão soa e vibra
  como os menus, com um `MenuFeedback` próprio (`AnswerFeedback`). Apontar outra resposta faz o clique
  e o pulso de mudar, confirmar faz o golpe e o pulso de escolher, e voltar o stick ao centro não soa.
  A roda não usa foco nem botões, por isso avisa o balão com o sinal `pointed`, e o balão chama o
  `play_move()` e o `play_confirm()` do `MenuFeedback`, que neste caso não ouve nada sozinho (Only
  Asked). A roda tem histerese: a resposta apontada só se larga quando o stick recua mais 0,12 do seu
  curso (Aim Release Margin) para lá da zona morta ou da linha entre duas respostas. Sem ela, um
  stick parado numa linha trocava de resposta a cada frame, e o destaque, o clique e o pulso com ele
  (no teste, 10 vezes em 20 oscilações na beira da zona morta; com ela, uma). Os pulsos estão
  gravados na cena, como os dos menus, e chegam ao jogo exportado.
- **Cruzes** (`scenes/screens/menu_crosses.gd`): seguem o foco, de teclado, comando ou rato, e
  deslizam para a opção selecionada; o rato por cima de um botão dá-lhe o foco. Ficam só nos botões:
  um slider mostra a sua própria seleção.
- **Letra:** Times New Roman em todo o jogo (menus, tutorial, falas, indicador de gravação e overlay),
  como fonte por omissão do projeto (`gui/theme/custom_font`, `themes/main_font.tres`), pedida ao
  sistema (no Windows existe sempre). A sua licença não
  permite incluí-la no jogo, por isso, onde não existir, entra a Tinos, com as mesmas medidas.
- **Tamanhos:** a primeira opção visível é sempre a maior (110 px, a variação MenuFirstOption do
  tema): Continue quando há gravação, New Game quando não há, Resume na pausa. As outras têm 64 px
  (MenuOption). Os tamanhos vêm todos do tema, nunca de um nó, e os testes dos menus confirmam-no.

#### Controlos: perfis e remapeamento

Os controlos seguem o modelo habitual nos jogos de PC: perfis predefinidos, um perfil personalizado
e remapeamento por captura da tecla seguinte.

- Nenhum perfil predefinido usa o rato; no Custom, qualquer ação pode receber um botão do rato.
- Os perfis só mudam o teclado e o rato das ações de jogo (andar, saltar, crucifixo, interagir). O
  comando, a pausa, o overlay de depuração e as ações dos menus ficam como o `project.godot` os
  define.
- Cada tecla está definida num único sítio. O perfil predefinido é o Input Map do `project.godot`,
  lido nas definições do projeto: uma tecla acrescentada em Project Settings ▸ Input Map passa a
  fazer parte dele. O perfil das setas está definido uma só vez, em `scenes/autoload/input_profiles.gd`, e deixa
  W, E, A, S e D livres para os upgrades. O Custom começa como cópia do predefinido.
- O `Settings` guarda o perfil escolhido e as teclas do perfil personalizado e aplica-os ao Input
  Map. Como nenhum script lê teclas diretamente, a personagem e o crucifixo não mudaram.
- No separador Controls (`scenes/screens/controls_menu.gd`), carregar no botão de uma ação do perfil Custom faz o
  ecrã esperar pela próxima tecla ou botão do rato. O Esc ou o B cancelam sem alterar nada. Uma
  tecla que não pode ser usada (as reservadas, como o F3 do overlay de depuração ou a tecla Windows) é recusada: o botão
  diz qual foi, soa o som de recusa, e a espera continua. O resto do comando, menos o B, também é
  recusado, com o texto «The controller can't be remapped (B cancels).», porque o comando é o mesmo em
  todos os perfis. Antes, era ignorado em silêncio, e o jogador não sabia se o jogo o tinha recebido.
  Um botão é recusado a cada carregão. Um eixo (o stick, um gatilho, como o RT do crucifixo) envia
  uma série de eventos ao longo do movimento, por isso é recusado uma só vez, quando passa de metade
  do curso, num sentido ou no outro, e só volta a sê-lo depois de regressar abaixo de 30 % do curso.
  Essa folga impede que o ruído de um carregão lento, a oscilar à volta de metade, conte como vários
  carregões. Cada espera começa sem eixos registados, porque um eixo largado fora da espera não é
  visto. Um modificador (Shift, Ctrl, Alt) só fica atribuído quando é largado, se
  entretanto nada mais foi carregado e o jogo não perdeu nem recuperou o foco, porque carregado pode
  ser o início de um atalho. Enquanto está em baixo, o botão diz «Let go of Shift to use it.». Antes, um
  Alt+Tab durante a espera deixava a ação com o Alt. Shift com outra tecla atribui a outra tecla. A
  tecla Windows não conta como modificador: está reservada e é recusada logo ao ser carregada,
  porque largá-la abre o menu Iniciar e tira o foco ao jogo; atribuída, abriria o Iniciar sempre que
  fosse usada a jogar. A espera apanha a tecla antes de qualquer outro nó, pelo que o Esc não fecha a
  pausa.
- Conflitos: se a tecla escolhida pertencia a outra ação, essa ação perde-a e, se ficar sem
  nenhuma, recebe as teclas antigas da primeira (troca). Nenhuma ação fica sem tecla. Preferiu-se a
  troca a um aviso de conflito, porque não deixa o jogador num estado em que uma ação não funciona.
- O `settings.cfg` guarda o perfil pelo seu identificador (por exemplo `arrows_and_qweasd`) e cada
  tecla como texto legível, com o nome da tecla ou do botão (por exemplo `key:Q`, `key:Ctrl` ou
  `mouse:left`), e nunca como números nem como objetos do Godot. Assim, o ficheiro lê-se e corrige-se
  à mão, acrescentar ou reordenar perfis não troca o perfil de quem já o tinha escolhido, e um
  ficheiro alterado à mão não cria objetos arbitrários. Um perfil ou uma tecla inválidos dão os
  valores predefinidos. O botão Reset to defaults das opções não mexe nos controlos; o separador
  Controls tem o seu próprio Reset.
- O `Settings` só altera uma ação no Input Map quando as teclas mudam: retirar uma tecla a uma ação
  solta essa ação, o que largaria uma tecla que o jogador estivesse a premir.
- Nos testes, o `Settings` guarda as opções só em memória e não lê nem escreve o ficheiro do
  jogador (`GameSettings.ignore_player_file`, ver "Testes e medidas").

O tamanho da letra e os espaços entre elementos estão num único tema, `themes/ui_theme.tres`, e nenhum
nó define o seu próprio tamanho de letra: uma futura opção de tamanho do texto altera apenas o tema.

#### Avisos do tutorial: faixa em baixo e último aparelho

Os avisos do tutorial do nível 1 (andar, saltar, salto na parede e crucifixo) aparecem numa faixa em
baixo, ao centro, e não no cenário. O sítio, as letras e as medidas resultam de uma pesquisa e de
capturas das quatro zonas do tutorial no nível com luz.

- Sítio. A faixa (`scenes/levels/prompt_band.tscn`) fica a 40 px do fundo do ecrã e tem 80 px de
  altura. Nas quatro zonas, em duas capturas, fica 41 a 82 px abaixo dos pés do homem, sobre o preto
  por baixo do chão, sem tapar o homem nem os buracos.
- Um aviso de cada vez: o primeiro, da esquerda para a direita, que a câmara vê e que o homem ainda
  não passou. Cada aviso fica pelo menos 2 s (`min_show_time` do nó Tutorial), para não piscar
  numa corrida. Este valor é uma estimativa, a confirmar num playtest. Enquanto a Velvet fala, a
  faixa esconde-se, para não ficar por baixo do balão.
- Leitura. A legenda usa a Literata (peso 600, 36 px) e o nome da tecla usa a Atkinson Hyperlegible
  Next (peso 700), uma letra desenhada para leitores com baixa visão. A placa é escura e
  semitransparente. O contraste da legenda medido nas capturas é de 16:1. Sobre um fundo branco
  seria de 6,8:1, acima do mínimo de 4,5:1 que a WCAG recomenda para texto.
- Teclado e comando. No teclado, o aviso desenha uma tecla com o nome da tecla do perfil escolhido.
  No comando, mostra o ícone do botão (Kenney Input Prompts, tingido com o bege da interface). Um
  botão sem ícone mostra o nome numa tecla. As letras, as cores e as molduras estão no tema
  (`themes/ui_theme.tres`, variações `Prompt*`); o tamanho do ícone (56 px) está no
  `scenes/levels/prompt_glyph.tscn`. Os ícones são lidos da pasta de cada família pelo nome do
  ficheiro (`Projeto/assets/ui/prompts/<família>/Double/`); a arte do grupo pode substituí-los
  mantendo os nomes, sem mexer no código.
- Família do comando. Os botões funcionam da mesma forma em qualquer comando: o Godot numera-os
  pelo sítio, e o botão de baixo tem sempre o índice do A da Xbox, seja a Cruz da PlayStation ou o
  B da Switch. O que muda é o desenho, e os avisos mostram o do comando em uso, em quatro famílias:
  Xbox, PlayStation, Nintendo Switch e Steam Deck. O `LastDevice` reconhece a família pelo nome que
  o Godot dá ao comando (por exemplo "PS4 Controller", "Nintendo Switch Pro Controller" ou "Steam
  Deck"); um nome desconhecido fica com o desenho da Xbox, que a maioria dos comandos de PC copia.
  A opção "Gamepad buttons", no separador Controls das opções, fixa a família à mão. É necessária
  quando o nome do comando não a revela: com o Steam Input ligado, a Steam apresenta um DualShock
  como se fosse um comando Xbox. O único botão sem ícone no pacote é o PS da PlayStation, que
  mostra o nome numa tecla.
- Ícones importados. Do pacote do Kenney só se importam os PNG de 128 px (`Double/`): as pastas
  `Default/`, `Vector/` e `Fonts/` de cada família têm um ficheiro `.gdignore`, que o Godot respeita
  ao importar.
- Troca automática. O autoload `LastDevice` (`scenes/autoload/last_device.gd`) guarda o último
  aparelho usado, porque o Godot 4.7 não tem uma função para isso. Conta apenas o que faria uma
  ação: uma tecla, botão ou gatilho premido, ou um stick inclinado para lá da zona morta dessa ação
  (0,2 no andar). Ecos, teclas largadas, o rato a mexer e um stick em repouso não contam, para que um
  stick com folga não faça os avisos trocar. Ligar um comando passa ao comando; desligar o último
  comando usado volta ao teclado.
- O `LastDevice` ouve o sinal `window_input` da janela, que recebe todos os eventos antes de qualquer
  nó, também em pausa, antes de qualquer menu os tratar. A alternativa, o `_input` de um nó, perdia
  os eventos que outro nó marcasse como tratados e os que uma lista aberta engolisse.
- Custo medido por evento: 0,5 a 0,7 µs com o aparelho em uso, porque um evento desse aparelho não
  pode mudar nada e sai logo; cerca de 11 µs para um stick em repouso com o teclado em uso, que tem
  de ser comparado com todas as ações.
- No `project.godot`, a opção `ignore_joypad_on_unfocused_application` está ligada, para que um
  comando pousado não mexa no jogo com a janela em segundo plano.
- A tecla da Velvet e a do portão continuam no cenário, com o desenho da faixa e a mesma troca: o
  `KeyPrompt` usa o mesmo `PromptGlyph`. Por isso, todas as teclas do cenário passaram de 80 px, com
  a letra dos menus, para 56 px, com a Atkinson Hyperlegible Next. Sem faixa, o `TutorialHints`
  desenha os avisos no cenário, como antes, e é o que acontece nas cenas antigas do nível 1.
- Testes: `test_last_device.gd` (o que conta, o que não conta, a pausa e os comandos) e
  `test_prompt_band.gd` (a tecla e o ícone, o sítio da faixa, o contraste, um aviso de cada vez e a
  Velvet).

#### Registo moral: escondido, uma soma e dois limiares

O jogo julga o homem pela forma como se joga, sem o mostrar. O autoload `Moral` guarda esse registo
num único sítio, e nada no ecrã o lê. As falas (ficheiros `.dialogue`) e as ofertas dos demónios
comunicam com ele apenas por sete nomes: aceitar uma tentação, recusá-la, o tom de uma resposta
(humilde ou arrogante), o tempo que o homem ouviu uma proposta antes de a recusar, se já aceitou uma
dada tentação, o estádio atual e o aviso de que o estádio mudou. Uma recusa fica contada para o
julgamento, mas não soma nem retira pontos.

Tudo o que o homem faz soma pontos a um único total. Uma tentação aceite soma o valor indicado para
ela, contando uma só vez, mesmo que volte a ser aceite. Cada portagem roubada no nível 3 vale menos
do que um atalho, porque esse nível tem três. Uma resposta arrogante soma meio ponto e uma humilde tira meio ponto. Ouvir uma proposta
só conta a partir de alguns segundos, e cada proposta tem um máximo; ouvida outra vez, por exemplo
depois de recomeçar a fase, conta apenas a escuta mais longa. Dois limiares transformam o total no
estádio 0, 1 ou 2, que escolhe as respostas que a alma ainda pode dar: quanto mais alto, menos
respostas humildes aparecem.
Cada resposta conta sempre que é dada. Por isso, uma conversa com respostas não se repete quando a
fase recomeça; essa regra pertence ao estado do jogo (`GameState`), que guarda as conversas já
ouvidas, e não ao registo moral.

Uma resposta humilde retira 0,5 pontos, e é a única coisa que retira pontos. O total nunca desce
abaixo de 0. Assim, a humildade pode compensar a soberba, mas um homem sem nada a pesar não fica com
pontos negativos. Antes, uma resposta humilde só ficava contada; o grupo decidiu que a humildade
deve pesar tanto como a soberba. A soma única foi preferida a contar apenas as tentações, que
ignoraria a soberba nas respostas, e a ter um limiar por categoria, que daria seis valores difíceis
de afinar e de explicar.

O tom também escolhe respostas diretamente. No presente da Asmodeu, a recusa humilde deixa de
aparecer se o estádio já subiu ou se a alma deu mais respostas arrogantes do que humildes
(`Moral.leans_arrogant()`). Assim, quem respondeu sempre com arrogância perde a resposta humilde,
mesmo antes de os pontos chegarem ao estádio 1. Contar as respostas não soma pontos. Como a alma só
diz o que o jogador escolhe (#277), a degradação vê-se no que ela já não consegue dizer, e nunca em
falas que o jogador não escolheu. O estádio 2 pede 3 pontos e quase não é atingido no nível 1 (o
atalho vale 1 e cada resposta arrogante 0,5), por isso o presente usa já o estádio 1.

| Valor | Referência |
|---|---|
| Atalho de um demónio (Moral Weight, no ficheiro da oferta em `scenes/autoload/offers/`) | 1 ponto |
| Dom de um demónio, como o charm (idem) | 2 pontos |
| Cada portagem roubada (idem) | 0,4 pontos |
| Tentação sem ficheiro de oferta (`scenes/autoload/moral_stats.tres`, tal como os seguintes) | 1 ponto |
| Resposta arrogante | +0,5 pontos |
| Resposta humilde | −0,5 pontos (o total nunca desce abaixo de 0) |
| Ouvir uma proposta | 0,1 pontos por segundo além de 3 s, até 0,5 por proposta |
| Estádio 1 / estádio 2 | a partir de 1 / de 3 pontos |

São valores de referência, a afinar em jogo. Com eles, um atalho basta para a alma perder a resposta humilde do presente, o atalho
e o dom juntos chegam ao estádio 2, e as três portagens juntas pesam pouco mais do que um atalho.
As regras estão numa classe sem nós
(`MoralRecord`), testada isoladamente; o autoload limita-se a disponibilizá-la. O `reset()` limpa o
registo para um jogo novo, e o registo entra na gravação do jogo.

#### Ofertas: tentações em dados

Todas as tentações do jogo passam por um único sistema, o autoload `Offers`. Cada oferta é um
ficheiro de dados (`OfferData`, em `scenes/autoload/offers/`) com quem a faz, o que oferece, o custo tal como o
demónio o diz, o efeito de a aceitar e o peso moral. O catálogo (`scenes/autoload/offers/offer_catalog.tres`)
reúne-as todas. Os níveis 2 e 3 acrescentam ficheiros e falas, sem código novo.

As falas usam três chamadas: `Offers.present` quando a proposta é feita, e `Offers.accept` ou
`Offers.refuse` com a resposta. Aceitar conta a tentação no registo moral uma só vez e emite o sinal
`accepted`. Recusar conta a recusa e o tempo que o homem ouviu a proposta, e emite `refused`. Quem
precisa de reagir ouve estes sinais, e o `Offers` não conhece nenhum deles: o `Main` muda de fase
num atalho e o nível retira o crucifixo das mãos do homem.

O efeito de uma oferta aceite só se aplica quando o balão de diálogo fecha. Assim, um atalho nunca
muda a fase com uma conversa aberta. Há dois tipos de efeito: ir para outra fase, que é o atalho,
e receber um upgrade, que são os dons. O atalho de Asmodeu leva ao fim do nível 1, com a mesma
passagem a preto das saídas de fase, e põe o homem no ponto de chegada (`ArrivalPoint`) junto à
tenda, na sala da Asmodeu, onde ela lhe oferece logo o dom. A gravação guarda esse ponto, pelo que uma morte ou o Continue o
devolvem à tenda, e não ao início da fase: um save point já alcançado não o leva para o seu ponto de
renascimento quando ele chega por um ponto de chegada. Perder o crucifixo não é o custo de uma oferta em
particular: é uma regra do jogo, guardada no `GameState`. O primeiro upgrade aceite, seja ele qual
for, tira o crucifixo.

Foi preferido um sistema único com dados a um script por oferta, porque, com sete níveis, cada
tentação nova obrigaria a escrever e testar código. O peso moral passou do `MoralStats` para o
ficheiro de cada oferta, para que cada valor exista num só sítio. Cada resposta acrescenta ainda
uma linha a `user://offers_log.csv`, com a oferta, a escolha, os segundos de escuta e o tempo de
jogo. Serve os playtests: permite verificar se quem aceita o atalho é quem está a ter
dificuldades.

Para cruzar com esse registo, cada morte acrescenta uma linha a `user://deaths_log.csv`. A linha
leva a hora, o nível, a fase, a zona, a causa da morte, o sítio (a fiada de picos, ou a causa) e a
posição, as mortes nesse sítio até então e se a morte trouxe
uma oferta do atalho. Os dois registos usam o mesmo código (`scenes/autoload/csv_log.gd`). Os testes não
escrevem em nenhum deles. O `test_deaths_log.gd` verifica o cabeçalho, uma linha por morte, a
marcação da morte que trouxe a oferta e que um caminho vazio não escreve nada.

O `test_offers.gd` verifica aceitar, recusar, aceitar duas vezes, uma oferta inexistente, o efeito
adiado até o balão fechar e o crucifixo perdido com o primeiro upgrade. O `test_offer_catalog.gd`
verifica os dados: ids únicos, todos os ids das falas presentes no catálogo, e um atalho que aponta
para uma fase e um ponto de chegada que existem. O `test_offer_shortcut.gd` percorre o atalho no
jogo, e o `test_dialogue_calls.gd` confirma que todas as funções chamadas pelas falas existem.

#### Balão de diálogo: retrato e saltar falas

As falas aparecem no balão do próprio jogo (`scenes/screens/dialogue_balloon.tscn`), feito a partir do balão
de exemplo do Dialogue Manager, como o plugin recomenda. O `addons/` fica como veio. Além do que o
exemplo já fazia (as falas a escrever-se, as respostas e o toque que mostra a fala inteira), o
balão mostra o retrato de quem fala. Até a arte chegar (S3), o retrato é provisório: um quadrado
com a cor da personagem e a inicial do nome. Os retratos finais entram no Inspector (Portraits), um
por personagem, sem mudar código.

Manter o Espaço premido durante 0,6 s (Skip Hold Time) salta as falas até à próxima com respostas,
ou até ao fim da conversa. Uma barra fina enche-se enquanto se mantém a tecla. O salto nunca escolhe
uma resposta pelo jogador e corre na mesma o que as falas saltadas fazem, como apresentar uma
oferta. Um toque curto continua só a avançar uma fala. O Dialogue Manager não tem esta função: o seu
autor recomenda acrescentá-la no balão, que é o que se fez. O número de falas saltadas fica nas
estatísticas da partida, para o julgamento final, e não conta para a moral.

O `test_dialogue_skip.gd` verifica que o salto para nas respostas sem escolher nenhuma, que a oferta
das falas saltadas é apresentada, que um toque curto não salta, que uma conversa sem respostas
termina e que o retrato provisório mostra a inicial.

Conversa em cena (#284). O balão avisa do início e do fim de cada conversa os nós do grupo
`talk_watchers`, e passa o nó onde foi colocado, que é quem fala. O `TalkFraming` da câmara pertence
a esse grupo. Assim, qualquer personagem que abra um balão recebe as barras e o enquadramento sem
ligações na cena do nível. Ligar os sinais de cada personagem no nível obrigaria a repetir a ligação
em cada personagem e em cada nível, e foi posto de lado. A conversa também não é um modo de câmara
(`CameraBrain`): os modos entram na troca da tecla F10, e a conversa é um momento passageiro, como as
cenas de câmara, com o mesmo `direct()` e `release()`. As contas do plano estão numa classe sem nós
(`TalkShot`), testada sozinha. O espaço livre por baixo da roda mede-se no ecrã, a partir dos lugares
das respostas: o palco do balão, com a caixa e a roda, está desenhado a 80 % do tamanho, a partir do
centro de cima, e o fundo da roda fica em y 613,6 num ecrã de 1080 px, e não em y 767, como as
coordenadas da cena sugerem. Uma cena de câmara pede à câmara a posição a que deve voltar
(`get_home_centre()`): enquanto volta do plano da conversa e durante dois frames de física depois de
devolvida, a câmara dá a posição que tinha sobre a personagem antes da conversa, e não o plano da
conversa. No regresso, a câmara fica livre para ser tomada (`let_be_taken()`): uma cena de câmara que a
peça nesse momento recebe-a no sítio onde está, e o regresso pára. A proteção contra golpes é um
só interruptor na hurtbox, partilhado com as cenas de câmara e com o agarrão; a conversa só o desliga
se foi ela a ligá-lo e se nenhuma cena de câmara tiver a câmara nesse momento. O `test_talk_framing.gd`
verifica as contas, a conversa com a Velvet (barras, zoom, plano parado, desvio para cada lado,
proteção e regresso), o fundo da roda e o seu limite com a Asmodeu, o Reduce Motion, as barras
desligadas, a conversa durante uma cena de câmara, a cena de câmara no fim da conversa e a proteção
que já estava ligada.

#### Estatísticas da partida: mortes, zonas e tempo

O autoload `RunStats` conta as mortes do homem por fase e por zona de cada nível. Estes números
servem as falas dos demónios (por exemplo, "morreste tantas vezes no mesmo sítio") e o julgamento
final, que mostra ao homem o que fez, com números. Nas falas, os números saem por extenso
(`RunStats.opening_words`, regras na classe `NumberWords`, `test_number_words.gd`): "Three falls on the way
to me" soa a uma voz, e "3 falls" a um contador. Não entram no registo moral: só as decisões
contam para a moral, e morrer não é uma decisão. Nada disto aparece no ecrã durante o jogo.

A fase é dada pelo próprio nível. Cada nível começa na fase indicada em First Phase, que
normalmente é 1. Os pontos de gravação que abrem uma fase têm o número dela em Starts Phase. No
nível 1, a fase 2 começa no `Phase2Save` e a fase 3 no `Phase3Save`. Ao arrancar, o nível fica na
fase do ponto mais avançado já alcançado. A zona de uma morte é a zona de câmara mais pequena que
contém o homem. Os níveis já estão divididos nestas zonas, com nomes de sítios, por isso não é
preciso marcar nada à parte. Fora de todas as zonas, a morte conta numa célula de 768 px
(Death Cell Size). A zona só se procura no momento da morte, e não em cada frame. Os números de cada
nível guardam-se em separado, para que a fase 1 do nível 2 não some às mortes da fase 1 do nível 1.

Cada morte guarda também a causa. Os picos chamam-se `spikes`. Um agarrão leva o nome da cena do
cão que agarrou (`demon`, `big_demon`, `biggest_demon`), ou o valor Cause do seu Hitbox, se estiver
preenchido. Com vários cães a agarrar, conta o primeiro. "O mesmo sítio" é a mesma zona e aquilo
que o matou. Cada fiada de picos conta por si (`Spikes1`, `Spikes2`...), porque há saltos mais
difíceis do que outros: quem morre sempre nos picos 2 não deve ouvir falar dos picos 1. Os cães
contam como uma matilha, pelo tipo, seja qual for o que o agarrou. Os picos e um cão na mesma zona
são, portanto, sítios diferentes, e as falas não os confundem. O mesmo critério pesa na pressão das
ofertas por mortes.

O `RunStats` mede também o tempo passado em cada fase, contado a partir do momento em que a fase
começa. O tempo não volta a zero quando o homem morre e para durante a pausa, porque o nível fica
parado. Não há relógio no ecrã: o tempo serve as falas (por exemplo, "já cá andas há dez minutos")
e o julgamento final. Um relógio visível daria ao jogo um ar de corrida contra o tempo, o que não
condiz com o tom nem com o pilar "julgado sem saber".

O `RunStats` fica fora do `GameState` porque a morte repõe o `GameState` como estava na última
gravação, e uma morte tem de ficar contada. As regras estão numa classe sem nós (`RunRecord`),
testada isoladamente no `test_run_record.gd`. O `test_level_run_stats.gd` verifica, no nível 1, a
fase ao arrancar e ao entrar no `Phase2Save`, a zona de uma morte e o tempo, que para durante a
pausa e se mantém quando a fase recomeça, e o aviso de uma oferta por mortes.

#### Ofertas por mortes: cada vez mais seguidas

Durante um nível, a única oferta é o atalho: saltar o resto do nível e ir diretamente ao fim. O
demónio do nível oferece-o no início das fases 2 e 3 e também quando o homem vai morrendo. A fase 1
faz-se sempre, por isso as mortes nela não trazem ofertas. O upgrade (o dom do demónio) só é
oferecido no fim do nível.

Cada morte nas fases 2 e 3 acrescenta "pressão": 1, mais 0,5 por cada morte que ele já teve no
mesmo sítio (a mesma zona e a mesma fiada de picos, ou o mesmo tipo de cão). Morrer sempre no mesmo
sítio traz a oferta mais cedo. Quando a pressão chega ao limiar, a zona dessa morte fica marcada, e a
pressão volta a zero. O primeiro limiar é sorteado entre 4 e 7, e cada limiar seguinte é 70 % do
anterior, nunca abaixo de 1,5, com uma variação sorteada de 15 % para cada lado. O jogador nunca
consegue contar até à oferta, mas sente que ela aperta à medida que falha.

As mortes contam sempre, mesmo com uma zona marcada. Podem estar várias zonas marcadas ao mesmo
tempo, por exemplo uma no início, onde ele morreu muitas vezes, e outra mais à frente, onde está a
sofrer agora. Cada uma espera por ele: quando volta a estar nessa zona, a Asmodeu aparece e fala
dessa zona, com as mortes e o tempo que ele lá passou. Uma zona já marcada não volta a ser marcada,
porque o limiar seguinte fica para outra zona. O jogo mede, por isso, também o tempo passado em cada
zona. Depois de ele aceitar o atalho, acabam as ofertas nesse nível.

| Valor (`scenes/autoload/offers/death_offer_stats.tres`) | Referência |
|---|---|
| Primeira fase com ofertas | 2 |
| Primeiro limiar | sorteado entre 4 e 7 |
| Peso de cada morte anterior na mesma zona | +0,5 |
| Cada limiar seguinte | 70 % do anterior |
| Limiar mínimo | 1,5 |
| Variação sorteada | ±15 % |

Com uma morte em cada zona, as ofertas chegam ao fim de 4, 3, 2, 2… mortes. Morrendo sempre no
mesmo sítio, a primeira chega à terceira morte. A regra vive numa classe sem nós
(`DeathOfferPacer`), testada no `test_death_offer_pacer.gd` com números fixos, sem sorteio. O
`RunStats` alimenta-a com cada morte, avisa quando há uma oferta à espera e guarda-a com as
estatísticas, para que a morte não a apague. Morrer não conta para a moral; só a resposta à oferta
conta.

A Asmodeu é um nó próprio (`scenes/characters/demon/asmodeus.tscn`), desenhada com a figura dela da
visual novel de CDJ, com 150 px de altura, e com o nome por cima. Não combate. Quando fala, aparece ao lado do homem, prende-o
como a Velvet (sem correr, saltar nem erguer o crucifixo), fala no balão do jogo e desaparece.
Enquanto fala, os cães do nível ficam parados (Asmodeus › Stills), para que nenhum morda o homem
preso. O que acontece a seguir decidem as falas, através das ofertas.

Quando é que ela fala decide outro nó do nível 1, o `AsmodeusDirector`, que só escolhe o cue:

| Momento | Cue |
|---|---|
| Primeira chegada ao início da fase 2 (o save point com Starts Phase 2) | `asmodeus_offer` |
| Primeira chegada ao início da fase 3 | `asmodeus_second_offer` |
| Com uma oferta por mortes à espera, ao entrar na zona dela (ou ao renascer lá dentro) | `asmodeus_deaths` |
| Ao entrar na sala dela, no fim do nível, aceite ou não o atalho | `asmodeus_gift` e depois `stairs` |

A zona de uma morte, do tempo e das ofertas é a zona que a câmara mostra, isto é, a última em que o
homem entrou. Antes era a zona mais pequena à volta dos pés dele, e as duas regras discordavam onde
as zonas se sobrepõem: num percurso do nível 1, em 1182 de 11168 frames (11 %). Por isso a Asmodeu
falava às vezes antes de ele entrar na zona que via, ou só depois de a ter passado. Durante uma cena
de câmara, que não segue o homem, vale a zona mais pequena.

Nas conversas fora da sala dela, a Asmodeu aparece no chão do homem, virada para ele: à frente dele a
180 px, ou mais perto, até 90 px, numa plataforma pequena; sem espaço à frente, atrás dele, e ele
vira-se. Só pisa rocha, nunca plataformas, e nunca fica sobre picos, perigos, um poço ou do outro lado
de uma parede. Se ele estiver numa plataforma ou onde ela não cabe, ela espera que ele avance. Dos
4998 pontos de rocha onde o homem pode estar no nível 1, ela não cabe ao lado dele em 210 (4,2 %),
sobretudo rebordos de um a dois tiles e fundos de poços estreitos.

A oferta por mortes só é verificada enquanto há uma à espera; sem ela, o diretor não faz nada a
cada frame. Uma conversa só conta como tida quando o homem responde à oferta. Nesse momento, o
diretor marca-a no `GameState` (`answered_` e o nome do cue), e a oferta por mortes deixa de estar à
espera. Se o jogador sair antes de responder, a conversa do início de uma fase volta assim que ele
pousa no chão depois do Continue, e a oferta por mortes continua à espera da sua zona. Aceitar o atalho fecha as ofertas por mortes.

A conversa do início de uma fase começa no ponto de gravação dessa fase (o sinal `reached`) e
espera que o homem pouse no chão. Até à #284, o `Phase2Save` só tinha uma caixa, à esquerda da boca
do poço por onde se chega à fase 2. Quem entrava pela boca ou caía direto na saliência não gravava a
fase 2 nem ouvia a Asmodeu, e uma morte levava-o de volta à fase 1. A caixa nova, `MouthAndLedge`
(232 × 96 px), cobre a boca e a saliência. Começa 8 px dentro do poço, para não apanhar o homem no
sítio onde renasce. O `test_phase2_save_entry.gd` verifica quatro entradas: pela beira esquerda, na
saliência, na boca ainda no ar (a gravação acontece e a conversa espera pelo chão) e o sítio onde
renasce, que não conta como chegada. A saída do nível (`PhaseExit` sem fase
seguinte e com Walk In Leads On desligado) só termina o nível depois da última fala de `stairs`;
nessa altura o diretor marca o nível como feito (`lust_done`), com a tenda como ponto de chegada,
o Main grava, escurece o ecrã e volta ao menu principal. Enquanto não houver nível 2, o Continue
depois disso leva o homem à tenda e deixa-o jogar no nível já feito, sem falas nem ofertas e com
os cães parados.

O nível 1 acaba numa sala da Asmodeu, depois do corredor de baixo da fase 3, com cerca de 27 × 19
tiles. Entre conversas, ela está lá de pé, à vista, num ponto próprio (`AsmodeusHome`, que o diretor
recebe em Home). As falas finais dizem-se desse ponto, e não ao lado do homem. As outras conversas
trazem-na para junto dele e, no fim, devolvem-na à sala. A saída do nível cobre o chão da sala
inteira (1296 px), para que o fim comece tanto ao entrar como ao chegar à tenda pelo atalho, que
fica dentro da sala. A sala tem zona de câmara própria (`ZoneP3AsmodeusRoom`, zoom 1,1), que mostra
o túnel de entrada e a sala do chão ao teto, sem mostrar o corredor de onde ele vem.

O `test_asmodeus.gd` verifica que o homem fica preso enquanto ela fala e é largado no fim. O
`test_lust_asmodeus.gd` joga o nível 1 dentro do Main: a Asmodeu à vista na sua sala desde o início e o dom dito de lá, a oferta do início da fase 2 recusada, uma
oferta por mortes que espera fora da zona e aparece ao entrar nela, o atalho aceite até à tenda, o
dom, as escadas e o regresso ao menu, e a oferta do início da fase 3. Os testes de percurso do
nível 1 retiram o diretor, tal como já não deixavam a Velvet falar, porque verificam o mapa e não as
conversas.

#### Gravação do jogo

O jogo tem três gravações automáticas, os slots, sem pontos de gravação visíveis no cenário:
chegar ao fim de uma fase é o checkpoint. Um jogo novo e cada entrada numa fase gravam no slot em
jogo, e o tutorial conta como uma fase: ao passar dele para a sala inicial, o nó `SavePoint` grava,
e dali em diante a fase 1 começa nessa sala. O fluxo está no `main.gd`; cada slot é um
`ConfigFile`, o mesmo recurso do Godot que guarda as opções.

| Guarda-se | Porquê |
|---|---|
| A cena da fase | É o ponto para onde o Continue regressa. |
| O número da fase e a hora da gravação | O menu mostra-os no slot, e a hora decide qual foi o último slot jogado. |
| O registo moral | O julgamento final depende de tudo o que o homem fez. |
| Se ainda tem o crucifixo | Perdê-lo é definitivo. |
| Os upgrades aceites | Os dons dos demónios ficam para os níveis seguintes. |
| O ponto de chegada na fase, se houver | Depois de um atalho, a morte e o Continue voltam lá, e não ao início da fase. |
| Os acontecimentos únicos, como já ter falado com a Velvet | Não se repetem, nem contam duas vezes. |
| O nome da alma | Só a fala da Velvet que o repete o usa (cue `named`); o ecrã do nome ainda não existe (#277). |

As estatísticas da partida (`RunStats`: mortes e tempo por fase) são a exceção no sentido contrário:
uma morte tem de ficar contada, por isso a morte nunca as repõe. Guardam-se num ficheiro próprio, ao
lado da gravação do slot (`save_run.cfg` ao lado do `save.cfg`), com a hora da escrita, em cada
gravação, em cada morte e ao sair para o menu ou fechar o jogo. O Continue repõe-nas e um jogo novo
apaga-as. Ficam fora da gravação para que a morte continue a não a alterar: o que lá está volta a
ser exatamente o que estava no último checkpoint.

Não se guardam os SP, os demónios, a câmara nem as tolerâncias do movimento: cada fase é uma cena
nova e reconstrói-os. As opções do jogador ficam em ficheiro próprio, porque não pertencem a uma
partida.

Até à gravação seguinte, o que o homem faz conta como não feito. A morte não grava: recomeça a fase
e repõe o autoload `GameState` e o registo moral tal como estavam na última gravação, e sair e usar
o Continue tem o mesmo efeito. As fases são curtas, pelo que não se perde muito. A exceção é um
upgrade aceite: não se pode desfazer, por isso o jogo grava logo que o homem o recebe, e uma morte
antes do checkpoint seguinte não o tira nem devolve o crucifixo. Uma resposta a uma oferta também
grava logo, porque é uma decisão: sair depois dela não faz repetir a conversa. Se a oferta aceite
tiver efeito (um upgrade, ou o atalho), a gravação fica para quando o efeito se aplica, no fim das
falas. Gravar o "sim" antes do efeito permitiria sair no intervalo e ficar com a oferta aceite sem o
que ela dá. Sair antes de responder não guarda nada, nem as respostas de tom dadas antes, e a
conversa repete-se no Continue. Um nível que não
inicia o jogo, como o Test room, fica fora disto: não grava nem repõe nada.
A gravação escreve primeiro uma cópia e só depois a coloca no lugar da anterior, para que um jogo
fechado a meio não destrua a última gravação. Uma gravação danificada, de uma versão mais recente
do que a do jogo ou de uma cena que já não existe não se pode continuar.

**Slots.** O slot 1 é o ficheiro que o jogo já usava antes dos slots, `user://save.cfg`; os slots 2
e 3 são o `save_2.cfg` e o `save_3.cfg`, cada um com as estatísticas ao lado. Por serem ficheiros
separados, um slot danificado não esconde os outros. Ficou de lado um ficheiro de índice com o
resumo dos três: seria uma segunda fonte da mesma informação, que um jogo fechado a meio podia
deixar desatualizada, e um índice danificado esconderia os três slots.

- **Continue:** aparece quando algum slot tem uma gravação utilizável e abre o último slot jogado,
  isto é, o da hora mais recente, seja a da gravação, seja a da última escrita das estatísticas.
  Quem joga sem chegar a um checkpoint e sai volta assim a esse slot, e não a outro gravado depois.
  A partir daí, tudo o que o jogo grava vai para esse slot.
- **Load:** aparece por baixo do Continue e lista os três slots, cada um com o nível, a fase, o
  tempo de jogo, as mortes e a data, escrita como 2026-11-19 17:40 para se ler da mesma forma em
  qualquer país. Abre com o último slot jogado selecionado. Um slot vazio, ou com um ficheiro que não
  se lê ("Unreadable save": estragado, de uma versão mais recente ou de uma cena que já não existe), aparece na lista, mas não se pode escolher. No caso mais comprido medido
  (10h 33m e 127 mortes), o texto ocupa 534 dos 600 px do botão.
- **New Game:** sem nenhum ficheiro de gravação, começa logo no slot 1. Caso contrário, mostra os
  slots com o primeiro vazio selecionado. Um slot ocupado, ou com um ficheiro que não se lê, pede
  confirmação antes de ser substituído, com a opção de o manter já selecionada.

**Versões.** O ficheiro guarda a versão do formato. A versão 2 é a dos slots e acrescenta a fase e
a hora. Uma gravação da versão 1, de antes dos slots, continua a abrir como slot 1: sem fase, e com a
data da alteração mais recente dos seus dois ficheiros, a gravação e as estatísticas. Se for do nível 1 sem luz, abre no nível 1 com luz, que o
substituiu no menu. A gravação seguinte passa-a à versão 2. A data mostra a hora deste computador
com o desfasamento de hoje em relação ao UTC, pelo que uma gravação feita do outro lado de uma
mudança de hora aparece com uma hora de diferença.

#### Sala de treino

A sala de treino (`scenes/levels/gym/gym.tscn`) permite experimentar cada mecânica isoladamente, sem
atravessar um nível. É composta por estações, cenas próprias em `scenes/levels/gym/stations/`, colocadas
lado a lado. Cada estação respeita o mesmo contrato:

- tem 1920 px de largura (um ecrã) e começa em x = 1920 · n, pela ordem de `Stations`;
- o topo do chão fica em y = 1000, nas coordenadas da estação;
- a placa (`GymHint`) fica em (90, 360), e o marcador `Start` é o ponto onde a personagem começa;
- a placa não pode cobrir nada com que se jogue, e tem de caber inteira no ecrã a partir do início,
  com a câmara já aproximada (o `test_gym.gd` verifica as duas condições).

Para acrescentar uma estação: instanciá-la em `Stations`, juntar o seu `Start` à lista `starts` do
nó `GymStations` e deslocar a parede direita (`WallRight`) e o `limit_right` da câmara mais 1920 px.

As placas usam texto claro sobre um painel opaco, com contraste de 17:1, acima do mínimo de 4,5:1
da norma WCAG AA, e letra de 36 px. Ficam baixas no ecrã: quando a personagem está parada, a
câmara aproxima-se e corta a parte de cima. Nas estações com cães, a personagem começa num patamar
200 px acima do chão, fora do alcance dos ataques (24 px de altura): pode ler a placa em segurança,
e o cão mostra o comportamento de quem não alcança o alvo.

Quem morre na sala recomeça no início da estação onde estava, e não no início da sala. Como o
recomeço cria uma cópia nova do nível, a estação fica guardada numa variável estática do
`GymStations`, que sobrevive à troca. A estação só é guardada quando o nível pede para recomeçar:
quem morre e sai para o menu antes disso volta a entrar na primeira estação. Este comportamento
pertence apenas à sala, e não é o checkpoint do jogo. As teclas 1 a 9 levam a personagem ao início
da estação correspondente, e o 0 à décima, mantendo os SP; não funcionam durante um agarrão, depois da morte, nem
quando a tecla está atribuída a uma ação no perfil Custom. Lêem as teclas diretamente, sem ações no
mapa de controlos, porque servem apenas para depuração; por isso não há equivalente no comando.

A estação 10 mostra os cães que saltam (ADR 0042), com os valores de `scenes/characters/demon/jumping_demon_stats.tres`:
o cão sobe um degrau de 96 px e não chega ao pilar de 144 px. O degrau vai até ao fim da estação,
porque os chãos se distinguem só pela altura: um cão que passasse para outro chão à mesma altura
do seu posto ficava preso à parede ao voltar. A queda de 240 px não aparece na sala, porque é mais
funda do que o salto e não tem volta. Esse ficheiro é uma cópia dos valores do cão da luxúria com
o salto ligado, usada só pela sala de testes e por esta estação, e não acompanha as mudanças do
original.

Ficam de fora as armadilhas, o checkpoint, que ainda não existe, e o diálogo, que ainda não é
iniciado por nada no jogo. A estação de cada uma acrescenta-se quando a mecânica entrar no jogo.

#### Atividade fora do ecrã

O nível 1 tornou-se mais lento noutro computador. O Godot já não desenha o que está fora do ecrã:
cada desenho, e cada bloco de tiles, só é enviado à placa gráfica quando aparece. O que continua a
custar em cada frame, esteja onde estiver, é o que se processa: os scripts e a física de cada cão e
de cada desenho do fundo com paralaxe. Na altura, antes da fase 3, o nível 1 tinha 86 cães e 850
desenhos com paralaxe. Mediu-se com o `measure_level1.gd` em cinco pontos do percurso, sem janela,
em nenhum dos quais havia cães no ecrã (2026-11-11, um computador ligado à corrente, uma execução):

| Nível 1, por frame | Frame inteiro | Scripts de física | Scripts de processamento |
|---|---|---|---|
| Como estava | 5,3 a 5,7 ms | 2,5 a 2,8 ms | 2,1 ms |
| Sem o processamento dos cães | 2,1 a 2,3 ms | 0,3 ms | 1,5 a 1,7 ms |
| Sem o da paralaxe | 3,9 a 4,1 ms | 2,6 a 2,7 ms | 0,6 a 0,7 ms |
| Sem nenhum dos dois | 0,37 a 0,50 ms | 0,2 a 0,3 ms | 0,05 ms |

Os cães, parados fora do ecrã, custavam cerca de 3,2 ms por frame, e a paralaxe cerca de 1,4 ms: em
conjunto, mais de 90 % do frame. A cena antiga da fase 2, com 33 cães e sem paralaxe, ficava abaixo
de 1,1 ms. Com janela, no ponto de partida, o mesmo computador desenhava a fase 2 e o nível 1 ao
limite de 144 imagens por segundo do ecrã, pelo que a diferença estava no processador e não na placa
gráfica.

A decisão foi adormecer o que está em repouso e longe do ecrã, e acordá-lo quando o ecrã se
aproxima. Fá-lo o `ActivityTracker` (`scenes/others/activity/activity_tracker.gd`), um nó da câmara
do jogo (`scenes/others/camera/game_camera.tscn`): qualquer nível com essa câmara o tem, sem mudar a
cena do nível. As regras são estas:

- A zona é o retângulo do ecrã, com o zoom das zonas de câmara, e não um círculo. O ecrã é
  retangular (16:9), e um círculo que lhe cobrisse os cantos manteria acordada uma área 1,84 vezes
  maior do que o ecrã.
- Um membro acorda quando o seu retângulo chega a 480 px do ecrã (Wake Margin) e adormece quando
  fica a mais de 960 px (Sleep Margin). Entre as duas distâncias, mantém o que estava, pelo que nada
  fica a alternar junto à margem. A diferença de 480 px corresponde a 0,67 s de corrida (720 px/s).
- Só adormece o que está em repouso. Um cão parado ou em ronda no seu chão pode adormecer; em
  qualquer outro estado (a perseguir, à procura, a voltar ao posto, no ar, projetado, a agarrar, e
  qualquer estado que se acrescente), continua a ser processado, esteja a que distância estiver. Um
  cão que persegue a personagem não para porque ela se afastou.
- Adormecer é o modo de processamento Disabled do Godot: o membro deixa de correr os scripts, as
  animações e os temporizadores, e as suas áreas saem da física, mas continua a ser desenhado se
  estiver no ecrã. Ao acordar, recupera o seu próprio modo. O corpo de um cão adormecido fica como
  obstáculo fixo (Disable Mode Make Static), pelo que um cão acordado nunca o atravessa.
- Cada membro é verificado dez vezes por segundo, repartidos pelos frames, e todos de uma vez no
  primeiro frame e quando o ecrã salta mais de 480 px num só frame, como num recomeço.
- Sem câmara, como nos testes, tudo fica acordado, a mesma regra dos sentidos dos demónios.
- Um ecrã inteiro à volta da personagem também conta como ecrã, esteja a câmara onde estiver. A
  câmara entrega a personagem ao rastreador. Quando a personagem é colocada noutro sítio, como ao
  escolher uma estação na sala de treino, a câmara desliza até ela, e durante esse tempo a
  personagem está fora do ecrã. Sem esta regra, num teste que põe a personagem dentro do anel do cão
  maior, a câmara ainda estava a mais de 5 400 px dela 30 frames depois, o cão continuava a dormir
  e o portão não abria; com ela, o portão abre no segundo frame.
- Numa cena de câmara, o caminho de cada deslocação também conta como ecrã. No início de cada
  deslocação, a cena entrega ao rastreador os ecrãs por onde a câmara vai passar, espaçados de meio
  ecrã, e o rastreador verifica todos os membros nesse frame. Uma deslocação rápida percorre mais de
  480 px em menos de dez frames, e um cão nesse caminho só seria verificado depois de já estar no
  ecrã, parado. Assim, os cães do caminho já se movem, e a paralaxe já desliza, quando aparecem. No
  fim da cena, o caminho deixa de contar, e o que ficou longe volta a adormecer.

O cão da luxúria (`lust_demon_stats.tres`) só começa uma perseguição no ecrã e desiste a 160 px
fora dele (ADR 0032 e 0038). Por isso, adormecê-lo quando está parado longe do ecrã não muda nada do
que o jogador vê. Um cão sem Chases Only On Screen fica acordado enquanto a personagem puder estar
dentro do seu alcance de visão. O campo Activity Reach do demónio alarga a zona de um cão que atue
sobre a personagem para lá do corpo. O cão maior da fase 3 junta à sua zona o anel que abre o portão
3, que chega a 736 px do centro: na vertical, o corpo e a margem de 480 px só cobririam 704 px, e um
cão adormecido não daria pela personagem dentro do anel. Como a zona segue o alcance do anel, um
anel maior continua coberto sem mais nenhum ajuste. O `test_biggest_dog.gd` verifica que a zona
contém o anel inteiro; sem esta regra, falhava.

Um desenho com paralaxe adormecido fica onde estava ao adormecer, que não é onde estaria com a
câmara atual. Por isso, a sua zona junta os dois sítios. Com uma profundidade baixa, o ecrã, ao
voltar, encontraria primeiro o sítio onde o desenho parou, e este apareceria parado no lugar errado.
No `test_parallax_activity.gd`, com profundidade 0,3, uma versão que só usava o sítio certo mostrava
o desenho parado em 53 frames, e a que junta os dois em nenhum.

Com o rastreador, o `measure_level1.gd` mediu o mesmo nível, antes da fase 3, com ele desligado e
ligado, em alternância, nos cinco pontos, em seis execuções seguidas (30 comparações), no mesmo dia,
com o computador a trabalhar com a bateria. Com a bateria, o processador trabalhava a cerca de dois
terços da frequência máxima, e os valores absolutos variaram mais do dobro de uma execução para
outra. Por isso, conta a comparação dentro de cada par (ADR 0048):

| Nível 1, por frame, com a bateria | Média | Pior frame |
|---|---|---|
| Rastreador desligado | 5,3 a 13,9 ms | 6,8 a 20,0 ms |
| Rastreador ligado | 0,7 a 2,8 ms | 1,4 a 5,2 ms |
| Sem o processamento de cães e paralaxe | 0,3 a 1,2 ms | |

Com o rastreador ligado, cada frame custou, na mediana dos 30 pares, 17,5 % do que custava desligado
(de 8,6 % a 38 %), menos 5,4 ms por frame. Ficaram acordados 32 a 105 dos 937 membros, conforme o
ponto. Sem o rastreador e com a bateria, o pior frame chegou a 20 ms, mais do que os 16,6 ms de um
frame a 60 imagens por segundo; com ele, não passou de 5,2 ms.

Ficaram de lado três alternativas:

- Zonas de atividade a partir das zonas de câmara (113 no nível 1, antes da fase 3). Nada mudaria a
  meio de uma sala, mas as zonas têm tamanhos muito diferentes, cada nível novo teria de as mapear,
  e o cão em perseguição precisaria na mesma de uma exceção.
- O `VisibleOnScreenEnabler2D` do Godot, que depende do desenho do ecrã. Esse desenho não existe
  nos testes sem janela, a mesma razão por que os sentidos dos demónios não o usam.
- Esconder o que está longe. O Godot já não desenha o que está fora do ecrã, pelo que não se
  ganharia nada.

O rastreador não tem uma lista do que adormece nem de exceções: cada membro diz onde atua e se pode
adormecer. Qualquer demónio (`Demon` ou uma cena que o herde) e qualquer `ParallaxSprite` é membro
sem código novo. Para tornar membro outra coisa, como uma plataforma que se move ou uma personagem
com lógica própria, o script chama `ActivityTracker.join(self)` no `_ready` e tem um método
`get_activity_rect()`, com o retângulo do mundo onde está ou atua, incluindo as áreas com que deteta
a personagem, porque essas saem da física enquanto dorme. Se tiver de continuar a ser processado
fora do ecrã em certos estados, tem também um `can_sleep()`, que devolve falso nesses estados. O que
tem de funcionar longe do ecrã, como um portão aberto por um desbloqueador distante, não deve ser
membro. O overlay de depuração mostra quantos membros estão acordados. O campo Enabled do
`ActivityTracker`, no separador Remote, desliga-o durante o jogo, para comparar.

O `test_activity_tracker.gd` verifica as regras com membros de teste, incluindo que um membro junto
da personagem, com o ecrã longe, acorda no frame seguinte e não volta a dormir enquanto ela lá
estiver. O `test_demon_activity.gd`
verifica que um cão a perseguir continua a mais de 7 800 px do ecrã, que um cão parado longe do ecrã
adormece e está acordado em todos os frames em que aparece, e que um cão a voltar ao posto só
adormece quando lá chega. Com o repouso mal definido, de modo a que tudo pudesse adormecer, o cão a
perseguir parava, e o teste falhava. O `test_parallax_activity.gd` verifica que um desenho
adormecido nunca está no ecrã. A verificação do `test_level1.gd` que põe os cães a patrulhar com a
personagem longe desliga o rastreador enquanto corre: ligado, adormeceria os cães longe do ecrã, e
estes não patrulhariam. Com todos os testes, antes e depois do rastreador, falham as mesmas
verificações (12 testes, das fases 1 a 3, já falhavam antes dele).

#### Som ambiente: camadas de sons soltos, fundos e o bus Alerts

O som ambiente de um nível (trovões, rajadas de vento, vozes) não é uma faixa em ciclo, porque um
ciclo, por mais longo que seja, acaba por ser reconhecido. Cada tipo de som é uma camada, um nó
`AmbienceLayer` (`scenes/others/ambience/ambience_layer.tscn`), que toca um som de cada vez, em
momentos e pontos escolhidos ao acaso:

- O intervalo entre o início de um som e o do seguinte é sorteado entre Min Gap e Max Gap (por
  omissão, 8 e 25 s).
- Cada som parte de um ponto ao acaso à volta do centro do ecrã: por omissão, até 900 px para cada
  lado e até 300 px para cima ou para baixo. O lado decide em que coluna se ouve mais, e a distância
  decide o volume. Enquanto toca, o som mantém o seu lugar no ecrã (Follow Screen): antes ficava no
  ponto do mundo onde começara, e, com a personagem a correr, ficava para trás, mais baixo e de lado.
- Os sons vêm de um `AudioStreamRandomizer` do Godot, no campo Sounds, que escolhe um som diferente
  do anterior e lhe varia o tom e o volume.

Assim, com poucos ficheiros, a sequência de sons não se repete. As camadas ficam dentro do nível, pelo
que a pausa as suspende com o resto do jogo; `start()` e `stop()` ligam-nas e desligam-nas por zona
ou por acontecimento. Ficaram de lado o `AudioStreamPlaylist` do Godot, que baralha faixas longas
mas não controla o espaço entre elas (dois trovões podem seguir-se) e acaba por as repetir, e o
FMOD, uma ferramenta externa, com licença e aprendizagem próprias, desproporcionada para três níveis.

Alguns sons trazem já a sua própria imagem estéreo, e o Godot não os deve colocar nem mover para um
lado: uma rajada cujo trajeto de um lado ao outro já vem no ficheiro, ou um ronco misturado ao
centro. Estes ficam no campo Unpanned Sounds da camada e tocam tal como estão, num leitor sem
posição (um `AudioStreamPlayer`, e não 2D), a −6 dB, o volume a que o Godot toca um som 2D ao
centro do ecrã. Quando uma camada tem os dois tipos, Unpanned Share é a parte dos sons que sai dos
não posicionados (por omissão, 0,33, um em cada três), e dois destes nunca tocam seguidos; em 3 000
sorteios, com três sementes, a parte medida foi de 0,325 a 0,341. Uma camada só com sons não
posicionados toca-os todos assim. Cada som diz também para que lado atravessa o ecrã: um não
posicionado, o lado que diz Unpanned Travel; um posicionado, do seu lado para o outro, porque uma
rajada que se ouve à esquerda sopra para a direita.

Por baixo das camadas tocam os fundos: sons longos e contínuos, como o vento, cada um num nó
`AmbienceBed` (`scenes/others/ambience/ambience_bed.tscn`). Um nível tem dois ou mais fundos, de
durações diferentes, que tocam ao mesmo tempo; como as durações diferem, a combinação dos dois
raramente se repete. Um fundo não repete o ficheiro em ciclo: toca-o em passagens, de Loop Start a
Loop End, e a passagem seguinte começa no outro dos seus dois leitores Crossfade segundos antes do
fim da anterior (por omissão, 3 s), numa transição de potência constante (seno e cosseno). Assim,
as entradas e saídas graduais e o silêncio no fim de um ficheiro ficam de fora, e o ficheiro não
precisa de ser um ciclo perfeito. O volume de cada fundo varia devagar entre Quiet dB e Loud dB,
segundo um ruído suave (FastNoiseLite), para que o vento respire em vez de ficar num nível fixo. A
primeira passagem começa num ponto ao acaso, pelo que o nível, e cada recomeço depois de uma morte,
abre num ponto diferente do som. O fundo conta o tempo real e não o do jogo, porque o som continua
durante o hitstop de uma morte; um frame conta no máximo 0,1 s, porque, no frame em que a escala de
tempo muda, o delta ainda traz a escala anterior.

No nível 1, a cena `scenes/levels/lust/lust_ambience.tscn` (o nó Ambience do `level1.tscn`) tem dois
fundos, `amb_layer_1.ogg` (68,5 s) e `amb_layer_2.ogg` (113,4 s), em `assets/audio/ambience/`.
Medidos com o ffmpeg, segundo a segundo, o primeiro entra aos poucos (−41 dB no primeiro segundo,
perto do nível do resto do ficheiro a partir dos 3 s) e ambos acabam em silêncio: o primeiro desce
a partir dos 63 s e cala-se dos 64,9 s aos 68,5 s, e o segundo desce a partir dos 107 s e cala-se
dos 109,5 s aos 113,4 s. Os fundos tocam, por isso, dos 3 aos 63 s e dos 0 aos 107 s, em passagens
de 57 s e de 104 s; a posição de um em relação ao outro só volta a ficar a menos de 1 s da inicial
ao fim de 5 928 s, cerca de 99 minutos.

Por cima dos fundos, o nível 1 tem duas camadas de vento, com os ficheiros em
`assets/audio/ambience/wind/`, uma pasta por categoria:

- PassingWind, as rajadas que passam, de 21 a 33 s umas das outras (cerca de 27 s, com um desvio ao
  acaso). O Godot coloca de um lado ou do outro `one_shot_wind_2.wav` (5,2 s) e
  `one_shot_wind_5.wav` (4,9 s); `one_shot_wind_1_bakedpan.wav` (6,2 s) toca sem posição, porque o
  trajeto já vem no ficheiro. Medida com o ffmpeg em janelas de meio segundo, a sua energia está
  mais à esquerda aos 0,5 s, ao centro a 1,0 s e quase toda à direita a 1,5 s.
- LowRumble, os roncos graves, de 11 a 19 s uns dos outros (cerca de 15 s): `one_shot_wind_3_low.wav`
  (8,0 s) e `one_shot_wind_4_low.wav` (5,8 s), todos sem posição, ao centro.

Cada camada escolhe os ficheiros com um `AudioStreamRandomizer`, que lhes varia o tom até cerca de
6 % e o volume até 1,5 dB.

Cada rajada que passa leva consigo algumas brasas, como de fogueiras fora de vista. O nó
`WindEmbers` (`scenes/others/ambience/wind_embers.tscn`) ouve a PassingWind e, a cada som, sopra
uma rajada para o lado para onde o som atravessa o ecrã; a do `_bakedpan` vai sempre da esquerda
para a direita. Entram 6 a 14 brasas, de 0,25 s a 1,15 s depois do início do som, pelo lado de onde
vem o vento e a alturas ao acaso, e atravessam o ecrã em cerca de 3 s com a rajada, que cresce em
0,45 s, se mantém 2,8 s e depois amaina. Sobem na diagonal: cada rajada sopra, em média, 6° acima
da horizontal (Slant), com um desvio ao acaso de 4°. Não seguem uma linha reta: a turbulência
(ruído de curl, levado pela própria rajada) desvia-as, as quentes sobem e as que arrefecem descem,
e as maiores, mais perto do olhar, vão mais depressa. Desde o #284, a cor de cada brasa vem das
cores das brasas dos fogos (Heat Ramp, do magenta escuro ao branco quente), com o brilho a 2,2, porque
no playtest de 22/11 o amarelo de antes destoava das cores do nível.

A sincronia entre as brasas e o som foi medida na mistura do próprio Godot, gravada com o modo de
gravação de filme (`--write-movie`): cada rajada atinge o pico 0,6 a 0,9 s depois de começar, com
as brasas já no ecrã. O que a tornava difícil de seguir era o volume: no pico, as rajadas ficavam a
cerca de −40 dBFS, o mesmo que o primeiro fundo quando sobe, e perdiam-se debaixo dele; e uma rajada
posicionada ficava para trás quando a personagem corria. Os roncos (LowRumble), também de vento e
sem brasas, ouviam-se então como se fossem a rajada, segundos depois. Por isso, além de a rajada
manter o seu lugar no ecrã, os fundos tocam agora num bus próprio, Beds, e as rajadas que passam
noutro, Gusts, ambos a enviar para o Ambience (e a seguir o seu volume nas opções). Um compressor no
Beds escuta o Gusts (sidechain), com o limiar a −27 dB, a razão de 2 para 1, ataque de 2 ms e
recuperação em 600 ms: enquanto a rajada sopra, os fundos baixam. Medido com um tom constante no
Beds e cada rajada no Gusts a −6 dB, os fundos baixam 4,5 a 6,2 dB no pico da rajada e recuperam em
cerca de 1,5 s. A primeira afinação (−30 dB, 3 para 1) baixava-os 7 a 10 dB, o que se ouvia como um
buraco. Ficou de lado subir simplesmente as rajadas 6 dB, que as punha mais fortes do que tudo o
resto em vez de abrir espaço para elas. O aspeto é o das brasas do
menu principal (`MenuEmbers`): a cor segue o calor, de um núcleo claro a um vermelho fundo; cada
uma é um rasto tão longo quanto o que percorre com o obturador de uma câmara de cinema aberto; e
cintila. Voam no mundo, à volta do que a câmara mostra, numa camada de desenho própria (um
`CanvasLayer`, na camada 1) que acompanha a câmara, como as rochas da frente do protótipo de
iluminação: dão luz, por isso a escuridão do nível (um `CanvasModulate`, que só escurece a sua
camada) não as apaga, e passam à frente do nível. A camada 1 deixa-as ainda debaixo do brilho e da
gradação de cor do protótipo, que chegam até ela. A pausa suspende-as. Na primeira versão, desenhadas
na camada do nível, não se viam: numa imagem do jogo, com 6 brasas no ecrã, só se distinguia um
traço; na escuridão do protótipo (0,30, 0,20, 0,30), nenhuma. Ficaram maiores (núcleo de 3 a 7 px),
mais quentes e mais brilhantes. Atravessavam então o ecrã em cerca de 1 s, com um obturador mais
curto (1/96 s), porque, a essa velocidade, um rasto longo espalhava a luz até ela desaparecer; a
3 s por travessia, voltaram ao 1/48 s do menu, e vivem 4,5 a 6 s, a arrefecer devagar, para ainda
brilharem do outro lado.

Com In Backdrop ligado, como no nível 1, as brasas voam no fundo do nível em vez de à frente de
tudo: desenham-se como o último filho do nó Backdrop do nível (o mesmo que o protótipo de
iluminação procura), por isso à frente das rochas do fundo e atrás da rocha onde se joga, da
personagem e de tudo o que vem depois. Aí, a escuridão do nível escurece-as, e Backdrop Brightness
(2,5 vezes) compensa-o; Backdrop Size (0,75) torna-as mais pequenas, como mais longe. Numa imagem do
protótipo, no fundo, as brasas veem-se sobre a parede da gruta com um brilho próximo do das da
frente, e nenhuma passa à frente da rocha do chão; desligado, voltam à sua camada e passam por cima
dela. Pode ligar-se e desligar-se com o jogo a correr, no separador Remote.

Medido pelo `test_wind_embers.gd`, em quatro rajadas para cada lado, 95 a 97 % atravessam o ecrã
todo, com a mediana em 2,9 a 3,05 s; afastam-se da linha reta 62 a 65 px (mediana), e 89 a 95 %
sobem pelo menos 100 px (mediana de 263 a 278 px, cerca de 8° na travessia). Antes de as rajadas
durarem mais, só 76 % chegavam ao outro lado: as últimas a entrar apanhavam a rajada já a amainar e
paravam a meio. Num minuto e dez de nível 1, sem nada forçado, as rajadas tocaram aos 21,4 s e aos
49,4 s e lançaram 8 e 13 brasas, e os roncos aos 13,6, 27,9, 43,6 e 59,0 s.

Ficaram de lado esperar pelo `MenuEmbers`, que ainda não está no dev, para lhe dar um modo de vento,
e as partículas do Godot (`GPUParticles2D`), que não reproduzem o aspeto das do menu. O desenho das
brasas (a cor pelo calor, o rasto e a cintilação) está num componente comum, `EmberLook`
(`scenes/others/ambience/ember_look.gd`), que o menu pode passar a usar quando chegar ao dev. As
brasas do fogo têm um aspeto próprio, o da chama (ver "Sons no mundo: o fogo e as suas brasas").

O som ambiente não pode tapar o que é preciso ouvir para sobreviver. Os sons do demónio e do
crucifixo tocam num bus próprio, Alerts, que envia para o SFX e segue por isso o volume dos efeitos
nas opções, sem opção própria. Dois compressores no bus Ambience baixam o ambiente (sidechain). O
primeiro escuta o Alerts, com o limiar a −40 dB, abaixo do som mais baixo do crucifixo, a razão de
20 para 1, para que todos os alertas baixem o ambiente quase o mesmo, e Mix a 0,75, que limita a
descida a cerca de 12 dB; volta em 500 ms. O segundo escuta o SFX, com o limiar a −20,5 dB e Mix a
0,5, que limita a descida a 6 dB; volta em 517 ms. Os sons da própria personagem (passos, saltos,
aterragens e o deslizar na parede) ficam no SFX e só passam esse limiar de raspão, pelo que o
ambiente respira com eles, sem oscilar a cada passo; como o Alerts envia para o SFX, os alertas
passam pelos dois compressores.

Cada som tem ainda um bus próprio, a 0 dB e sem efeitos, por baixo da sua categoria, só para se
misturar no painel Audio do editor: SFX › Player (PlayerJump, PlayerLand, PlayerWallSlide,
PlayerFootsteps), SFX › Demon (DemonLatch, DemonJump, DemonAttack, DemonCrucifixHit), Alerts
(DemonAlert, CrucifixCue, CrucifixHold, PlayerLowSP), Beds (Bed1, Bed2) e Ambience (LowRumble, Fire).
São 18 buses, que não mudam a mistura nem as opções: cada um segue o volume, os compressores e as
opções da categoria para onde envia. O Godot mistura os buses do último para o primeiro, e um
compressor só ouve o que lhe chega antes de ele próprio ser misturado; por isso os buses novos
ficam no fim da lista, depois de todos os compressores que escutam as suas categorias, e os buses
antigos mantêm a sua posição. A alternativa, um bus por grupo (Player, Demon), dava menos buses,
mas os sons de cada grupo continuavam a partilhar o mesmo volume.

Com o limiar antigo de −20 dB, os sons do crucifixo (no bus, entre −32 e −24 dB) não chegavam a
baixar o ambiente, e ouviam-se mal; e os do demónio, que passavam pelos dois compressores, sem
limite, baixavam-no 33 a 36 dB. Medido pelo `test_ambience_ducking.gd`, com um tom constante no
Ambience: os sons do crucifixo baixam agora o ambiente 10,3 a 14,3 dB, os do demónio 16,9 a 17,1 dB,
e os da personagem 0,4 a 2,3 dB. O ambiente volta a menos de 1 dB do normal 1,6 s depois de um som do
crucifixo acabar e 1,9 s depois de um do demónio (a menos de 0,3 dB, 2,2 e 2,6 s): o compressor do
Godot recupera mais devagar quanto mais o som passou do limiar, e o ambiente regressa aos poucos.

O `test_ambience_layer.gd` verifica, com um som silencioso criado em memória, que cada intervalo
fica entre Min Gap e Max Gap e que os intervalos variam; que os sons partem dos dois lados do centro
do ecrã, dentro dos limites, ou da própria camada quando não há câmara; que um som posicionado
mantém o seu lugar no ecrã quando a câmara se move 800 px; que tocam no bus Ambience;
que `stop()` e a pausa os suspendem; que os sons não posicionados tocam do centro do ecrã, no seu
leitor, nunca dois seguidos, e dizem o seu lado, e que os posicionados atravessam do seu lado para
o outro; que as duas camadas de vento do nível 1 têm os intervalos, os ficheiros e os buses acima
(as rajadas no Gusts, os roncos no LowRumble, que envia para o Ambience); que o Beds e o Gusts
enviam para o Ambience, um compressor no Beds escuta o Gusts e cada fundo do nível 1 toca no seu
bus, que envia para o Beds; e que o Alerts envia para o SFX, o compressor do Ambience o escuta, o
alerta do demónio e os sons do crucifixo chegam ao Alerts e os da personagem chegam ao SFX sem
passar pelo Alerts. O `test_ambience_ducking.gd`
toca, com o áudio a misturar em tempo real e sem saída, cada som do crucifixo, do demónio e da
personagem, lidos das cenas, e verifica que cada alerta baixa o ambiente entre 5 e 18 dB e cada som
da personagem 3 dB no máximo; demora cerca de 100 s. Se os alertas se ouvem bem por cima do
ambiente confirma-se a jogar. O `test_settings.gd` confirma a lista de buses: os cinco com
opção de volume, todos a enviar para o Master, o Alerts, a enviar para o SFX, o Beds, o Gusts e o
Thunder, a enviar para o Ambience, os três buses dos trovões, a enviar para o Thunder, e os 18
buses de cada som, cada um a enviar para a sua categoria; e verifica que estes últimos estão a
0 dB, sem efeitos, chegam ao Master e ficam depois dos compressores que os escutam.

O `test_ambience_bed.gd` verifica, também com um som silencioso, que um fundo toca nos seus dois
leitores, no bus Ambience; que entra a partir do silêncio, nunca passa de Loud dB e depois varia
entre Quiet dB e Loud dB; que a passagem seguinte começa em Loop Start, no outro leitor, Crossfade
segundos antes do fim da anterior, e que a potência total durante a transição fica a menos de 2 %
da constante (no teste, 0,0 %); que a primeira passagem começa num ponto ao acaso; que `stop()`
desliga o fundo em Fade Time e `start()` o traz de volta; que a pausa o suspende; que, com a escala
de tempo do hitstop, a passagem seguinte chega ao fim de 4,93 s de tempo real, em vez de 5 s; e que
os dois fundos do nível 1 tocam no Ambience ou num bus que chega a ele (o Bed1 e o Bed2, pelo Beds), cada um com o
seu som, e só se realinham ao fim de
mais de meia hora. Se o ambiente se repete ou respira bem só se ouve a jogar.

#### Trovões e relâmpagos

O nível 1 tem uma trovoada fora de vista, em três camadas, seguindo as indicações de quem fez os
sons (Diogo, do grupo), com os ficheiros em `assets/audio/ambience/thunder/`:

- ThunderBacklayer, o fundo da trovoada, a camada mais baixa: `thunder_spontaneous_backlayer_1.wav`
  (17,7 s) e `_2.wav` (15,6 s), de 32 a 48 s uns dos outros (cerca de 40 s, com um desvio ao acaso),
  ao centro, sem posição. Nunca tocam os dois ao mesmo tempo: o intervalo mais curto, 32 s, é mais
  longo do que o ficheiro mais longo no tom mais grave, 18,4 s.
- ThunderBackground, os trovões ao longe: `thunder_background_1.wav` (3,9 s) e `_2.wav` (4,0 s), de
  9 a 15 s uns dos outros (cerca de 12 s), cada um entre 50 e 80 % para um lado escolhido ao acaso.
- ThunderMain, os trovões principais: `thunder_1.wav` (4,9 s) e `thunder_2.wav` (7,6 s), um
  relâmpago de 26 a 38 s depois do anterior (cerca de 32 s). Primeiro vê-se a luz e só 2 a 6 s
  depois se ouve o trovão, a 35 % para o lado de onde veio a luz.

Em todas, o ficheiro é escolhido ao acaso e o tom varia até 4 % de cada vez. As duas primeiras são
camadas de ambiente (`AmbienceLayer`); a terceira é um nó próprio, `ThunderLayer`
(`scenes/others/ambience/thunder_layer.tscn`), porque toca o som segundos depois do acontecimento
que o anuncia. Cada trovão principal é um recurso `ThunderStrike` (em
`scenes/others/ambience/strikes/`), que junta o som e o relâmpago que o precede.

Os trovões guardam a imagem estéreo e a reverberação com que foram gravados. Para os pôr de um lado,
os buses ThunderBackground e ThunderMain têm um efeito Panner do Godot, que o nó acerta antes de
cada som: o Panner passa parte de um canal para o outro em vez de baixar um deles, e o som mantém a
largura e o volume. Ficou de lado colocar o som num leitor 2D ao lado do ecrã, como as rajadas,
porque o lado dependeria então da distância no ecrã e do zoom da câmara, e não do valor pedido. Como
o Panner move tudo o que toca no bus, dois sons da mesma camada nunca se sobrepõem: no ThunderMain,
o intervalo mais curto (26 s) é maior do que o atraso mais longo e o trovão mais longo no tom mais
grave somados (13,9 s); no ThunderBackground, 9 s contra 4,2 s.

Cada camada tem o seu bus, e os três enviam para um bus Thunder, que envia para o Ambience: os
trovões seguem a opção de volume do ambiente e baixam com ele debaixo dos alertas. Medidos com o
ffmpeg (norma EBU R128), os ficheiros principais têm −20,0 e −26,5 LUFS, os de fundo −28,7 e −31,0
LUFS e os do fundo da trovoada −21,3 e −25,5 LUFS: estes últimos, os mais fortes depois do
`thunder_1`, têm de ser os mais baixos. Os leitores estão a −6 dB, como os sons sem posição das
outras camadas, o ThunderBacklayer a −12 dB e os outros dois a 0 dB; somados os ganhos, antes do
Ambience, o fundo da trovoada fica entre −39 e −44 LUFS, os trovões ao longe entre −35 e −37 e os
principais entre −26 e −33. Afinam-se a ouvir, no painel de áudio do Godot.

O relâmpago é a luz que um nó `LightningFlash` (`scenes/others/ambience/lightning_flash.tscn`)
desenha sobre o fundo do nível: um shader, desenhado como o último filho do nó Backdrop (como as
brasas do vento), ilumina de cor-de-rosa (1,0; 0,45; 0,82) o que o fundo mostra, mais do lado de
onde veio o relâmpago, sem tocar na rocha onde se joga nem na personagem. É uma primeira versão,
feita para ser substituída: o `ThunderLayer` só anuncia cada relâmpago (com um sinal), e outro
shader com os mesmos parâmetros, ou outro nó que ouça o mesmo sinal, muda o aspeto sem mexer no som.
Ficaram de lado tingir todo o fundo, que não mostra de que lado veio a luz, e uma camada de luz à
frente de tudo, que parece o flash de uma câmara e é mais agressiva para quem é fotossensível. Numa
imagem do nível 1 durante o primeiro relâmpago, vindo da esquerda, o fundo fica rosa, mais claro à
esquerda, e a rocha, a personagem e as indicações do tutorial ficam como estavam.

A luz segue a forma de cada trovão. Medidos em janelas de 50 ms, o `thunder_1` é um estalo
próximo: forte desde os primeiros 50 ms, com uma segunda explosão entre 0,6 e 0,75 s, e já 24 dB
abaixo do pico a 1,5 s. O `thunder_2` é um trovão que rola, com o pico 8,8 dB abaixo: o golpe
principal aos 0,4 s, forte até 1,4 s, duas subidas aos 1,9 e 2,6 s, e apaga-se até cerca de 4,5 s.
Um script fora do repositório transforma esta medição na curva de luz de cada `ThunderStrike`, duas
vezes mais rápida do que o som: cada pico forte (pelo menos 5 dB acima das quebras à sua volta e a
menos de 12 dB do pico do ficheiro) é um clarão, que sobe em 25 ms e cai para cerca de um terço em 0,12 s, e
o rolar do trovão é um brilho mais fraco por baixo. O brilho segue a raiz quadrada da amplitude, mais
próxima do que se vê e do que se ouve do que uma relação direta. O `thunder_1` dá dois clarões, aos
0,09 e 0,33 s, com o brilho máximo, e apaga-se em 1,9 s; o `thunder_2`, com 0,60 do brilho, sobe
num brilho que rola durante 0,35 s, tem três clarões, aos 0,40, 0,70 e 0,97 s, e apaga-se em 2,8 s.
As curvas podem ser corrigidas à mão no Inspector.

Por causa da fotossensibilidade, nada pisca mais de três vezes num segundo (critério da WCAG). O
script só mantém um clarão se nenhum segundo ficar com mais de três e se estiver a pelo menos 0,2 s
de outro; contando como um clarão uma subida e uma descida de pelo menos um décimo do brilho máximo,
o `thunder_1` pisca 2 vezes e o `thunder_2` 3 vezes no segundo em que mais pisca.

O `test_thunder.gd` verifica que os três buses dos trovões enviam para o Thunder, e este para o
Ambience, que os dois buses com lado têm um Panner e que o do fundo da trovoada é o mais baixo; que,
em 16 relâmpagos, cada trovão chega dentro do atraso pedido depois da sua luz, com o mesmo som, do
mesmo lado, com o pan e o tom pedidos, que os relâmpagos ficam entre o intervalo mais curto e o mais
longo e vêm dos dois lados; que `stop()` suspende os relâmpagos mas não um trovão já anunciado, e a
pausa suspende os dois; que a luz se desenha em último lugar no fundo, vem do lado do relâmpago,
segue a curva do relâmpago frame a frame e apaga-se quando ela acaba; que uma camada de ambiente com
Side Pan põe cada som para um lado, dentro dos limites; que os dois relâmpagos do nível 1 não piscam
mais de três vezes num segundo; e que as três camadas do nível 1 têm os intervalos, os ficheiros, os
buses e os lados acima. Se a luz e o som combinam confirma-se a jogar.

#### Sons no mundo: o fogo e as suas brasas

O som de uma coisa do mundo, como uma fogueira ou um cão-demónio, é um nó
`SoundEmitter` (`scenes/others/ambience/sound_emitter.tscn`): um som contínuo em ciclo (Loop) e,
por cima dele, sons soltos (One Shots) a momentos ao acaso, para que o ciclo não se reconheça. O
emissor anda com a coisa, por isso serve também para o que se mexe.

O volume depende da distância entre a coisa e o ouvido, que é a personagem do nível onde o emissor
está (sem nível, como numa cena aberta sozinha, o centro do ecrã; o campo Ear pode apontar outro).
Dentro de Near Distance, ouve-se como junto à coisa; daí até Hearing Distance, desce como diz a curva
Falloff, que se desenha no Inspector; a partir de Hearing Distance, cala-se. Sem curva própria, o
emissor usa uma que desce cerca de 6 dB de cada vez que a distância duplica, como ao ar livre, e se
cala no fim: metade (−6 dB) a um quinto do caminho, um quarto (−12 dB) pouco antes do meio, um
décimo (−20 dB) a três quartos, e zero no fim. O emissor acerta o volume dos seus leitores a cada
frame e desliga a atenuação do próprio Godot; o lado (esquerda e direita) continua a ser o do Godot,
pelo ponto do ecrã onde a coisa aparece. O fogo ouve-se até 900 px e por inteiro até 120 px.

Antes, o volume era o do Godot: ouvia-se a partir do centro do ecrã, (1 − distância / 1 500 px)
elevado a 1,5. Com as fogueiras do protótipo a 1 000 a 1 300 px umas das outras, ouviam-se sempre
duas ou três ao mesmo tempo: numa passagem medida ao longo de uma fila, a soma ia de −0,7 dB junto
a uma fogueira a só −4,5 dB a meio caminho da seguinte, uma diferença de 3,8 dB, que mal se ouve. E
o centro do ecrã nem sempre segue a personagem: a câmara para nos limites das zonas e não se mexe
dentro da sua janela, e aí aproximar-se do fogo não mudava nada. Medido pelo `test_sound_emitter.gd`
com a câmara parada, de junto a uma fogueira até meio caminho da seguinte (1 296 px), a soma das
fogueiras descia 0,0 dB; agora desce 14,3 dB. Ficaram de lado ouvir a partir do centro do ecrã,
mantendo o problema da câmara parada, e pôr um `AudioListener2D` na personagem, que mudaria também
o lado e o volume de todos os outros sons 2D do jogo.

O emissor só toca o ciclo enquanto o ouvido está mais perto do que Hearing Distance, e só o desliga
100 px mais longe (Hearing Margin), para que andar nessa fronteira não o ligue e desligue a cada
frame. Assim, das 87 fogueiras do protótipo de iluminação, só as próximas tocam, e as outras não
gastam processamento a descodificar o ficheiro. O ciclo começa num ponto ao acaso, para que duas
fogueiras nunca toquem em passo. O ficheiro importa-se sem ciclo, como o Godot faz por omissão; o
emissor toca uma cópia que repete, sem alterar o ficheiro nem a sua importação.

Um ficheiro pode acabar numa cauda, como a reverberação do último momento. O `fire_base_layer.ogg`
(15,5 s) é estável até aos 10,735 s, onde o som direto para de repente, e os 4,8 s seguintes são só
a reverberação a morrer; o ficheiro, exportado do FL Studio, não traz marcas de ciclo. Repetido
inteiro, a cada volta o fogo morria na cauda e calava-se uns segundos. Com Loop End, cada passagem
toca até ao fim, cauda incluída, e a seguinte começa em Loop Start quando a anterior chega a Loop
End, por cima da cauda dela, no mesmo leitor (até três ao mesmo tempo). Medido na mistura do Godot,
começando aos 10 s, o fogo mantém-se entre −41 e −38 dB através de Loop End; antes caía 27 dB em
2,5 s.

Os sons soltos vêm, em média, a cada Interval (por omissão, 4 s), com cada espera sorteada até
Deviation para cada lado (1,5 s: entre 2,5 e 5,5 s), e só enquanto o emissor se ouve. Escolhe-os um
`AudioStreamRandomizer`, que não repete o anterior e lhes varia o tom até 5 % e o volume até 2 dB.
Cada um vem um pouco ao lado da coisa, até Pan Spread do campo estéreo para cada lado (0,1: um
equilíbrio de 50/50 passa, no máximo, a 40/60). O Godot não tem um controlo de panorâmica nos
leitores 2D: o lado de um som vem do ponto do ecrã onde está, e um som a uma largura de ecrã do
centro desloca-se 0,25 do campo estéreo. Por isso, o som solto toca deslocado para o lado (cerca de
590 px do mundo com o zoom de 1,3 das zonas de câmara do nível 1), com o volume da coisa: como o
emissor calcula o volume pela distância da coisa ao ouvido, o lado só muda a panorâmica. A conta foi
confirmada na mistura do Godot: um som 400 px à direita do centro saiu 1,232 vezes mais forte à
direita do que à esquerda, como a conta diz. Pela mesma conta, um som junto à borda do ecrã fica a
62,5/37,5 (cerca de 4,4 dB), o que nas colunas de um portátil quase não se ouve; a força da
panorâmica de todos os sons 2D é Project Settings › Audio › General › 2D Panning Strength (0,5, o
valor do Godot), e a de um só leitor o seu Panning Strength. O emissor conta o tempo real, como os fundos, e a pausa
suspende-o.

Ficaram de lado deslocar o som solto só dentro da largura da chama (10 % da largura do ecrã, cerca
de 190 px, mudaria o equilíbrio apenas 0,025, o que não se ouve); um efeito de panorâmica num bus
por som solto, porque os buses são de todo o projeto e dois estalos de fogueiras diferentes ao
mesmo tempo partilhariam o mesmo; e tocar todas as fogueiras sempre, deixando o Godot silenciar as
distantes, porque as 87 continuariam a descodificar o ficheiro.

A cada som solto, o nó `RisingEmbers` (`scenes/others/ambience/rising_embers.tscn`), que ouve o
emissor, lança 4 ou 5 brasas (Count, no nó `RisingEmbers` da cena do fogo) da metade da chama de
onde o som se ouve. Cada uma sai com velocidade
(70 a 160 px/s) e ângulo (até 25° da vertical, para cada lado) próprios, com o estalo; depois o
calor leva-a para cima, mais devagar à medida que arrefece, e a turbulência (ruído de curl)
desvia-a; apaga-se ao fim de 1,5 a 3 s.

O aspeto segue o da chama, e não o das brasas do vento. A chama é uma animação desenhada, plana,
com um contorno escuro, pintada pela rampa de cor do fogo (de um vinho escuro, pelo magenta e o
rosa, até um pêssego); as faíscas desenhadas na própria animação são pequenas lascas cor-de-rosa
com esse contorno. As brasas do fogo são também lascas planas: pequenos triângulos irregulares (7 a
14 px de comprido), cada um com a sua forma, contornados no vinho mais escuro da rampa, que rodam
ao subir. A cor vem do calor, pelas cores da rampa do fogo: saem entre o rosa e o pêssego, passam
ao magenta ao arrefecer e desvanecem-se antes de chegar ao vinho, como as faíscas da chama, que se
apagam ainda rosadas; e encolhem para 40 % à medida que ardem. A primeira versão usava o aspeto das
brasas do vento, pontos luminosos laranja com halo e rasto: numa imagem do jogo, ao lado da chama
rosa e desenhada, liam-se como de outro jogo. Numa segunda imagem, as brasas já frias ficavam
triângulos escuros, que pareciam cinza; por isso desvanecem-se ao arrefecer. Ficou de lado manter
os pontos luminosos e mudar só a cor, porque continuariam a ler-se como luz fotográfica ao lado de
uma chama desenhada. Como as do vento, desenham-se numa camada própria (`CanvasLayer` 1), que a
escuridão do protótipo não apaga, e passam por isso à frente da rocha. No protótipo, uma fogueira
que o homem não vê não lança brasas, mas ouve-se, tal como a sua luz se vê à volta das esquinas.

Para não parecerem paradas, cada brasa arde: tem um pequeno brilho (bloom), um halo suave somado por
cima dela, com 2,6 vezes o seu comprimento, que cintila ao seu próprio ritmo (5 a 11 Hz) e enfraquece
ao arrefecer; e a sua cor sobe até 12 % mais quente com a cintilação, sem nunca ficar mais fria do
que o seu calor. O brilho desenha-se noutra camada de desenho, por cima das lascas, em modo aditivo,
e o seu acaso é independente do do voo, pelo que o voo das brasas ficou igual. Numa imagem do
protótipo, as lascas quentes têm um halo rosado ténue, e as frias apagam-se sem ele.

O fogo é a cena `scenes/others/ambience/fire_sound.tscn`, que junta o emissor e as brasas com os
ficheiros em `assets/audio/textures/fire/`: o ciclo `fire_base_layer.ogg` (15,5 s) e quatro estalos
em `crackles/`, de 0,9 a 2,9 s. O protótipo de iluminação põe um em cada fogueira, com as brasas a
sair da metade central da chama, entre 50 e 85 % da sua altura. Os sons tocam no bus Fire, que envia para o Ambience:
seguem o volume do ambiente nas opções e baixam com os alertas.

O `test_sound_emitter.gd` verifica que, fora de um nível, o emissor ouve a partir do centro do ecrã;
que o ciclo só toca dentro de Hearing Distance, continua na margem e para além dela, com a atenuação
do Godot desligada; que repete sem alterar o ficheiro, e que dois emissores começam em pontos
diferentes; que o ciclo do fogo continua através de Loop End, medido na mistura; que, em 30 sons
soltos, cada espera fica dentro de Deviation de Interval e há sons dos dois lados; que, pelas contas
do próprio Godot, com o zoom 1,3 e a coisa em vários pontos do ecrã, cada som solto desloca o
estéreo pelo seu lado de Pan Spread e soa tão alto como da coisa, também com o ouvido em movimento;
que, medido na mistura do Godot, um som solto à direita desloca o estéreo 0,100 e soa 1,000 vezes
tão alto como o ciclo; e que, com um ouvido próprio, o volume segue a curva de omissão em cada um dos
seus pontos, ou uma curva própria. Verifica ainda que desligado se cala, que a pausa suspende os sons
soltos, que o fogo tem os seus ficheiros e tempos, que cada uma das 87 fogueiras do protótipo tem o
seu som, com as brasas a sair da chama, e que as fogueiras ouvem a partir da personagem. O `test_rising_embers.gd` verifica, em 18 estalos, que
cada um lança 1 ou 2 brasas, o Count de omissão do nó (8 lançaram 1 e 10 lançaram 2), da sua
metade da chama; que cada estalo do som do fogo lança 4 ou 5 (os dois estalos medidos lançaram 5); que todas
sobem (de 71 a 262 px), 89 % acabam pelo menos 15 px para um lado (17 para a esquerda e 8 para a
direita), afastam-se da linha reta 14 px (mediana) e a mais rápida sobe 2,8 vezes mais depressa do
que a mais lenta; que se apagam dentro da sua vida e não fica nenhuma; que uma fogueira escondida
não lança nenhuma; que a pausa as suspende; que as cores das brasas do fogo são todas da rampa
da chama, com o contorno no seu vinho mais escuro; e que o brilho de cada brasa se desenha depois
dela, em modo aditivo, varia 76 % no primeiro segundo e cai de 0,135 para 0,047 do primeiro ao
último terço da sua vida. Se o fogo soa bem, e se as brasas se veem bem, só se confirma a jogar.

#### Sons no mundo: os cães-demónio

Os sons próprios dos cães, em `Projeto/assets/audio/sfx/demons/`, usam o mesmo emissor do fogo: o
volume vem da distância entre o cão e a personagem, e o lado, do ponto do ecrã onde o cão aparece.
Cada cão tem cinco, cada um num nó `SoundEmitter` próprio, filho do nó `DemonSounds`:

| Som | Quando toca | Ficheiro |
|---|---|---|
| Alert | Ao reparar na personagem, com o "!". | `demon_dog_alert.wav` (1,8 s), no bus Alerts |
| Latch | Quando o som de alerta acaba, mais Latch Gap (0 s), se o cão ainda a perseguir; não toca se, entretanto, desistiu, a foi procurar ou foi atirado. | `demon_dog_latch_1.wav` (1,2 s) ou `demon_dog_latch_2.wav` (2,4 s), ao acaso |
| Jump | Ao saltar para um degrau, ao descer de uma borda e, com Jump On Lunge, ao atirar-se à personagem. | `demon_dog_jump.wav` (0,13 s), provisório |
| Attack | Quando uma mordida ou um salto acerta na personagem, também quando a agarra. | `demon_dog_attack.wav` (0,18 s), provisório |
| CrucifixHit | Quando o crucifixo o atira; não quando a personagem se solta dele, nem enquanto o crucifixo o continua a empurrar no ar. | `demon_dog_cruci_hit_1.wav` (1,8 s) ou `demon_dog_cruci_hit_2.wav` (1,4 s), ao acaso, com o tom a variar até 4 % |

Os quatro últimos tocam no bus SFX. Ouvem-se por inteiro até 150 px (Near Distance) e calam-se aos
1 200 px (Hearing Distance), com a curva de omissão do emissor. Cada um liga-se e desliga-se no seu
Enabled, e o volume, as distâncias e a curva acertam-se no próprio nó. Cada cão toca-os com a sua
voz, como os bips. Os dois sons provisórios são cópias de sons da personagem, tocadas 1,3 vezes
mais depressa (cerca de 4,5 meios-tons acima, e por isso mais curtas) e cortadas com um
desvanecimento: o salto vem de `player_jump.wav` (0,28 s) e o ataque de `hard_land.wav` (0,38 s).
Para os trocar, basta substituir o ficheiro.

Os bips provisórios continuam nos seus lugares do `DemonSounds` e só tocam, no leitor `Cue`, com
Play Beeps. Com Use Old Alert, o alerta volta a ser o bip antigo, e o Latch toca depois dele.

Antes, todos os sons de um cão tocavam num só leitor, e cada som novo parava o anterior. Com bips de
0,14 s, nunca se notou; com um alerta de 1,8 s e sons de até 2,4 s, um salto logo a seguir ao "!"
cortaria o alerta a meio. Por isso, cada som tem o seu leitor. O nível 1 tem 99 cães, e cinco
emissores em cada um mediriam a distância perto de 500 vezes por frame. Com Plays On Its Own
desligado, um emissor sem ciclo só toca quando o cão lho pede e dorme entre sons, sem
processamento; acorda só enquanto o som dura, para lhe acertar o volume.

A escolha entre dois ficheiros e a variação do tom vêm do gerador de números do próprio cão, como
nos bips: o `AudioStreamRandomizer` do Godot tira números do gerador global, de onde cada demónio
tira a sua semente (ADR 0040). O randomizer fica no Inspector como a lista dos ficheiros, com os
seus pesos e o seu Random Pitch, que o `DemonSounds` lê; o seu Random Volume Offset não se usa. Por
passo de física, todos os cães juntos começam no máximo 3 alertas, 2 saltos, 2 ataques e 2 golpes
do crucifixo (Max Notice Sounds, Max Leap Sounds, Max Attack Sounds e Max Hit Sounds Per Step),
contados à parte, para que um bando se ouça como um só sem calar um alerta.

Ficaram de lado: um só leitor com várias vozes, porque no Godot mudar o ficheiro de um leitor para
o som que estava a tocar; leitores simples com a atenuação do Godot, que se ouve a partir do centro
do ecrã e quase não muda com a distância (ver o fogo); e deixar o randomizer escolher, porque
mudaria as sementes dos demónios.

O `test_demon_sounds.gd` verifica, em 17 casos, que a cena tem os cinco sons com os seus ficheiros e
buses, a dormir, e os bips desligados nos seus lugares; que nenhum bip toca por omissão; que cada
som toca no seu momento e que o salto não corta o alerta; que o golpe do crucifixo só toca quando o
crucifixo atira o cão, e uma vez por arremesso, e que em 24 golpes se ouviram os dois ficheiros; que
o Latch começou 1,700 s depois do alerta, para 1,716 s esperados (o alerta ao tom desse cão), 2,250 s
para 2,253 s com Latch Gap 0,5 s e 0,133 s para 0,146 s depois do bip antigo, e que não tocou nos
cães que voltaram ao posto, foram procurar ou foram atirados; que cada som se cala com Enabled
desligado; que os limites por passo se cumprem; e que fazer um cão e tocar todos os seus sons não
tira números do gerador global. Se os sons dos cães soam bem, só se confirma a jogar.

#### Sincronia dos sons da personagem e do crucifixo

Cada som toca no passo de física do acontecimento (salto, aterragem, erguer ou baixar o
crucifixo) ou, nos passos, no frame da animação em que o pé assenta. A latência de saída do áudio,
medida no Godot com o controlador WASAPI do Windows, é de 10,7 ms. O desfasamento que se sentia
estava nos ficheiros, medidos amostra a amostra:

- Cada um dos três ficheiros de passos tinha dois impactos, o segundo 143 a 145 ms depois do
  primeiro e só 3 a 9 dB mais baixo, separados por um silêncio a −50 dB. A correr a 600 px/s, com um
  passo a cada 220 px (367 ms), ouviam-se quatro batidas por ciclo onde se veem dois pés. Cada
  ficheiro foi cortado nesse silêncio em dois sons de um só impacto, `footstep_1.wav` a
  `footstep_6.wav`, o que também duplica a variedade.
- Nenhum passo se perdia: no nível 1, cada pé que assenta no desenho dispara o som e o som
  começa. Mas os seis ficheiros diferiam 7 dB entre si (nos 10 ms mais altos, de −34,0 a
  −27,1 dBFS), e cada passo chega ao bus SFX 8 a 13 dB abaixo do ficheiro: a distância ao centro do
  ecrã tira 2 a 5 dB e o panorama 2D cerca de 6 dB, porque o Godot toca um som 2D centrado a metade
  do nível em cada coluna. Com o ambiente, que oscila devagar entre cerca de −57 e −37 dBFS, os
  passos mais baixos ficavam apenas 3 dB acima dele e perdiam-se. Os seis ficheiros foram
  igualados ao mais alto (+0 a +6,9 dB, com picos até −16 dBFS), e o volume dos passos passou a ter
  um campo próprio, Footstep Volume (0 dB). Medidos no nível 1, a correr, os passos chegam agora
  ao bus a −35,5 a −39,1 dBFS, 9 a 19 dB acima do ambiente no instante de cada um, e continuam
  abaixo do salto e da aterragem suave, cujos ficheiros, que fazem o mesmo caminho até ao bus, são
  1,4 e 3,6 dB mais altos.
- O salto e três sons do crucifixo ganham corpo tarde, enquanto a imagem muda de imediato: o salto
  chega ao máximo aos 60 ms, o erguer aos 120 ms, o baixar sobe durante 80 ms e o som de crucifixo
  disponível fica abaixo de −50 dBFS nos primeiros 107 ms. Cada um começa agora a meio do ficheiro,
  num ponto afinável no Inspector: o salto a 0,03 s, o erguer a 0,07 s, o baixar a 0,03 s e o
  disponível a 0,1 s. Os ficheiros não mudam. O Godot começa o som de imediato nesse ponto, sem
  entrada gradual (confirmado numa captura da mistura), e o salto do silêncio para a primeira
  amostra fica entre −39 e −84 dBFS, pelo menos 17 dB abaixo do pico de cada ficheiro.
- As aterragens não mudaram: chegam a 4 dB do máximo nos primeiros 10 ms.

O `test_player_sounds.gd` verifica que cada som de passo, lido do ficheiro, tem um só impacto e
que os seis diferem 1 dB no máximo, que cada passo toca em Footstep Volume e que o salto começa em
Jump Start; o `test_crucifix_sounds.gd`, que o erguer, o baixar e o som de
disponível começam no seu ponto. Se a sincronia está certa confirma-se a jogar.

### Convenções de código

- GDScript com tipagem estática em variáveis, parâmetros e retornos. O código tipado gera bytecode
  mais rápido.
- Composição em vez de herança: comportamentos como vida, dano ou movimento vivem em nós-componente
  reutilizáveis, e não numa cadeia de subclasses.
- "Call down, signal up": um nó pai pode chamar métodos dos filhos, e um filho comunica para cima
  por sinal. Nunca `get_node("../..")`. No jogo, a única exceção é o crucifixo, explicada em
  "Crucifixo: componentes e modificadores de movimento". Fora do jogo, o overlay de depuração fere
  a personagem com o F4 (ver "Overlay de depuração").
- Valores de balanceamento em `@export` ou em `Resource`, e nunca como constantes no meio da lógica.
- Nomes em inglês; `snake_case` para ficheiros, funções e variáveis; `PascalCase` para classes e
  nós.
- Física e movimento em `_physics_process()`, incluindo qualquer deslocação de um nó. Em
  `_process()` fica apenas o que não altera posições, como texto e cores (ver Physics interpolation).

### Git

- Os ficheiros `*.import` e `*.uid` são versionados. Sem eles, quem clonar o repositório reimporta
  tudo e as referências entre recursos deixam de funcionar.
- `Projeto/.godot/` não é versionado: é uma cache local, regenerada na primeira abertura.
- `export_presets.cfg` é versionado (presets partilhados); `export_credentials.cfg` não é, porque
  contém chaves de assinatura.
- Recursos movem-se e renomeiam-se apenas no painel FileSystem do Godot, que atualiza as
  referências e os UIDs. O explorador de ficheiros do sistema não o faz.

## Créditos

- Dialogue Manager 4.1.0, de Nathan Hoad. Licença MIT. Plugin de diálogo, em
  `Projeto/addons/dialogue_manager/`. https://github.com/nathanhoad/godot_dialogue_manager
- `demon_alert.wav`, `demon_search.wav`, `demon_take_off.wav` e `demon_land.wav`, em
  `Projeto/assets/audio/sfx/`: bips provisórios gerados por síntese de ondas sinusoidais, sem
  material de terceiros. Saem quando chegarem os sons definitivos.
- `demon_dog_jump.wav` e `demon_dog_attack.wav`, em `Projeto/assets/audio/sfx/demons/`: cópias
  provisórias de `player_jump.wav` e `hard_land.wav`, tocadas 1,3 vezes mais depressa e cortadas,
  feitas com o ffmpeg. Saem quando chegarem os sons definitivos.
- `amb_layer_1.ogg` e `amb_layer_2.ogg`, em `Projeto/assets/audio/ambience/`, e os sons soltos do
  vento, em `Projeto/assets/audio/ambience/wind/`: os fundos e as rajadas de ambiente do nível 1,
  feitos por Diogo, do grupo, por edição e mistura de sons com licença CC0 (domínio público), que
  não pede atribuição e permite qualquer uso, incluindo o vídeo, as apresentações e o portefólio.
- `fire_base_layer.ogg`, em `Projeto/assets/audio/textures/fire/`, e os quatro estalos, em
  `Projeto/assets/audio/textures/fire/crackles/`: o som das fogueiras, feito por Diogo, do grupo,
  por edição de sons com licença CC0 (domínio público), que não pede atribuição e permite qualquer
  uso, incluindo o vídeo, as apresentações e o portefólio.
- Os seis trovões, em `Projeto/assets/audio/ambience/thunder/` (`thunder_1.wav`, `thunder_2.wav`,
  `thunder_background_1.wav`, `thunder_background_2.wav`, `thunder_spontaneous_backlayer_1.wav` e
  `thunder_spontaneous_backlayer_2.wav`): os trovões de ambiente do nível 1, feitos por Diogo, do
  grupo, por edição e mistura de sons com licença CC0 (domínio público), que não pede atribuição e
  permite qualquer uso, incluindo o vídeo, as apresentações e o portefólio.
- Os cinco sons dos cães-demónio, em `Projeto/assets/audio/sfx/demons/` (`demon_dog_alert.wav`,
  `demon_dog_latch_1.wav`, `demon_dog_latch_2.wav`, `demon_dog_cruci_hit_1.wav` e
  `demon_dog_cruci_hit_2.wav`): o alerta, o ataque depois do alerta e o golpe do crucifixo, feitos
  por Diogo, do grupo, por edição e mistura de sons com licença CC0 (domínio público), que não pede
  atribuição e permite qualquer uso, incluindo o vídeo, as apresentações e o portefólio.
- `level1_cave_map.png` e `level1_cave_shade.png`, em `Projeto/assets/sprites/backgrounds/`:
  imagens provisórias feitas a partir do mapa do nível 1, sem material de
  terceiros. A primeira dá a cor de cada área do fundo e a segunda escurece o fundo junto à rocha.
  Na zona da fase 3 e na sala da Asmodeu, foram repintadas por scripts fora do repositório que
  ajustam um modelo às imagens das fases 1 e 2 e só alteram os píxeis por onde essas zonas passam.
  Saem ou refazem-se quando o mapa ou as áreas mudarem.
- `fire_low_sheet.png`, `fire_bonfire_sheet.png`, `fire_leaning_sheet.png` e
  `fire_creeping_sheet.png`, em `Projeto/assets/sprites/fire/`: fogos animados desenhados por von
  Hafe, do grupo, convertidos dos GIF originais em folhas de frames. Usados pelo protótipo de
  iluminação (#257; os três últimos desde a #263).
- `bramble.png`, em `Projeto/assets/sprites/traps/`, e `platform_slab.png`, em
  `Projeto/assets/sprites/environment/`: a silva dos picos letais e a laje das plataformas,
  desenhadas por von Hafe, do grupo, recortadas e reduzidas dos PNG originais (#263). A silva foi
  substituída na #284 pela versão nova, desenhada pelo grupo, recortada e reduzida da mesma forma.
- `collapsing_slab_sheet.png`, em `Projeto/assets/sprites/environment/`, e `gate_door_sheet.png`,
  `gate_frame_back.png`, `gate_frame_front.png` e `unlocker_statue_sheet.png`, em
  `Projeto/assets/sprites/gates/` (#284): a laje que se parte, o portão (porta parada, a abrir e a
  fechar, poste e pilar) e a estátua do desbloqueador (apagada e acesa), desenhados pelo grupo,
  convertidos dos GIF e WEBP originais em folhas de frames, todos com o mesmo recorte por objeto,
  para ficarem alinhados.
- `velvet_walk_sheet.png`, em `Projeto/assets/sprites/velvet/`: a Velvet a andar, 8 frames,
  desenhada pela Sofia, do grupo, com o fundo branco tornado transparente e reduzida da folha
  original (#263).
- `asmodeus.png`, em `Projeto/assets/sprites/asmodeus/`: a figura da Asmodeu, desenhada pelo Cisco,
  do grupo, para a visual novel de CDJ, recortada e reduzida do PNG original (#263).
- `soul_frame.png`, `soul_aura_1.png` a `soul_aura_8.png`, `cross_ready.png`, `cross_spent.png` e
  `power_arrow.png`, em `Projeto/assets/sprites/hud/`: a barra de alma (moldura, aura animada, as duas
  cruzes do crucifixo e a seta dos poderes), desenhadas pelo grupo, usadas tal como foram entregues.
- Sons dos menus, em `Projeto/assets/audio/ui/` (#267), todos de domínio público (CC0), cortados,
  filtrados e misturados pelo `tools/audio/make_menu_sounds.py`, cada um à intensidade do seu evento
  (ver "Aspeto dos menus"):
  - `menu_move_1.wav` a `menu_move_4.wav` (mudar de opção): cliques de rato: «mouse_click.wav», de
    Six Ways (https://freesound.org/s/223445/), «mouse-click-single-00.flac», de pbimal
    (https://freesound.org/s/534103/), «Mouse 2 Button Fast Click», de aphom000
    (https://freesound.org/s/687107/), e `mouseclick1`, do pacote «51 UI sound effects (buttons,
    switches and clicks)», de Kenney
    (https://opengameart.org/content/51-ui-sound-effects-buttons-switches-and-clicks).
  - `menu_confirm_1.wav` e `menu_confirm_2.wav` (escolher): os dois primeiros cliques de rato, cada
    um com «Mute Bass Drum.wav», de Lynx_5969 (https://freesound.org/s/418725/), saturado para se
    ouvir em colunas pequenas.
  - `menu_back_1.wav` (voltar): o primeiro clique de rato, mais grave, com o mesmo bombo, mais baixo.
  - `menu_refuse.wav` (recusa ao remapear): o som de voltar duas vezes, a segunda 90 ms depois e
    mais grave.
  - `menu_tick.wav` (barras deslizantes): `tick_001`, do pacote «Interface Sounds», de Kenney
    (https://opengameart.org/content/interface-sounds).
  - `menu_switch.wav` (interruptores): «Small_Flashlight_Click_on_02.wav», de Rudmer_Rotteveel
    (https://freesound.org/s/457463/).

  Os sons do Freesound vêm das pré-visualizações (OGG); os originais em WAV pedem uma conta no site
  e substituem-nas na versão final.
- Tinos, de The Tinos Project Authors. SIL Open Font License 1.1. Letra de reserva dos menus, com as
  medidas da Times New Roman, em `Projeto/assets/fonts/` (com a licença em `Tinos-OFL.txt`).
  https://github.com/googlefonts/tinos
- Atkinson Hyperlegible Next, de The Atkinson Hyperlegible Next Project Authors, e Literata, de The
  Literata Project Authors. SIL Open Font License 1.1. Letras dos avisos do tutorial, em
  `Projeto/assets/fonts/` (com as licenças em `AtkinsonHyperlegibleNext-OFL.txt` e
  `Literata-OFL.txt`), copiadas do repositório google/fonts (https://github.com/google/fonts), que
  as publica a partir dos repositórios de origem: https://github.com/googlefonts/atkinson-hyperlegible-next
  e https://github.com/googlefonts/literata
- Kenney Input Prompts 1.5A, de Kenney (www.kenney.nl). Domínio público (CC0). O pacote inteiro,
  uma pasta por família de comando, em `Projeto/assets/ui/prompts/` (com a licença em
  `Kenney-License.txt`); o jogo usa os ícones de 128 px das famílias Xbox, PlayStation, Nintendo
  Switch e Steam Deck. https://kenney.nl/assets/input-prompts

## Licença

Ver [LICENSE](LICENSE).

# P2D

Aventura de plataformas 2D desenvolvida em Godot 4 para a unidade curricular de
**Projeto de Jogo 2D** (Mestrado em Desenvolvimento de Jogos Digitais, Universidade de Aveiro).
Tema: *Destroy Yourself*. Título por decidir.

Um homem que se considera justo acorda no inferno, convencido de que está ali por engano, e tem de
subir sete níveis, um por pecado capital, sem poder atacar. Cada demónio oferece-lhe um atalho, e o jogo regista o que ele
aceita.

> **Estado:** a personagem jogável já anda, salta e tem controlo no ar, desliza nas paredes e salta
> delas, e o salto tolera pedidos ligeiramente fora de tempo. O jogo abre num menu principal, que dá
> acesso à sala de teste e ao blockout do nível 1, e tem pausa e opções gravadas. A câmara do jogo
> está descrita em "Câmara". Na sala de teste, dois demónios perseguem a personagem, mordem-na e,
> com o SP baixo, agarram-na; o crucifixo afasta-os, e quem morre recomeça a sala. Ainda não há
> arte, e o som começou pela personagem e pelo crucifixo.

Este documento tem duas partes. A primeira descreve, para toda a equipa, o que já pode ser
experimentado e as medidas que servem o desenho de níveis. A segunda, "Para quem programa",
documenta a organização técnica do projeto.

## Experimentar

1. Instalar o Godot 4.7.x, versão standard (não a versão .NET).
2. No Project Manager, importar `Projeto/project.godot`. O projeto Godot encontra-se na subpasta
   `Projeto/`, e não na raiz do repositório.
3. Premir F5. O jogo abre no menu principal: Play mostra a lista de níveis, Options abre as opções
   e Quit fecha o jogo. Uma cena aberta com F6 corre sozinha, sem menus nem pausa.
4. A sala de teste tem um bloco elevado, com duas bordas, para experimentar os saltos a partir de
   uma borda, e uma chaminé de 120 px entre a parede esquerda e um pilar suspenso, por baixo do qual
   se entra a andar. A sala é maior do que o ecrã, e a câmara segue a personagem desde o início. Para
   a direita há uma corrida longa, uma escada de quatro degraus de 200 px, uma segunda chaminé de
   120 px junto à parede direita e, no topo desta, uma passagem que termina numa queda de 1500 px.
   Há dois demónios, um no chão da corrida longa e outro na passagem do topo (ver "Demónios").
   Durante o jogo, a tecla F3 mostra e esconde o texto de depuração descrito em "Overlay de
   depuração", e a tecla F4 retira 10 SP à personagem, como um golpe, para experimentar a
   regeneração descrita em "SP".
5. O nível 1 em blockout (Play ▸ Level 1: Lust (blockout)) tem as fases 1 e 2, com tiles
   provisórios de 48 px, cada uma na sua cena. A fase 1 sobe da esquerda para a direita e termina
   numa sala com uma porta; ao atravessá-la, o ecrã escurece e a fase 2 começa no canto inferior
   direito. Os retângulos amarelos assinalam os checkpoints provisórios e o verde a porta para a
   fase seguinte. Cada fase também corre sozinha com F6.

Os controlos de teclado e rato escolhem-se em Options ▸ Controls, entre três perfis. O comando é
igual em todos.

| Ação | Teclado e rato (predefinido) | Setas e QWEASD | Comando |
|---|---|---|---|
| Andar | A / D ou setas | setas | stick esquerdo |
| Saltar | Espaço | Espaço | A / Cross |
| Deslizar numa parede | no ar, A / D ou setas contra a parede | no ar, setas contra a parede | stick esquerdo contra a parede |
| Saltar de uma parede | no ar, Espaço encostado à parede | no ar, Espaço encostado à parede | A / Cross encostado à parede |
| Erguer o crucifixo | premir o botão esquerdo do rato no chão; fica erguido enquanto premido | premir Q no chão; fica erguido enquanto premido | premir RT / R2 no chão; fica erguido enquanto premido |
| Soltar-se de um demónio | premir Espaço repetidamente | premir Espaço repetidamente | premir A / Cross repetidamente |
| Interagir | E | Ctrl | B / Circle |

O terceiro perfil, Custom, começa igual ao predefinido, e cada ação pode receber outra tecla ou
botão do rato. O Esc, o F3 e o F4 estão reservados. As teclas W, E, A, S e D do perfil das setas
ficam livres para os upgrades.

| Ação | Teclado | Comando |
|---|---|---|
| Pausar e retomar | Esc | Start |
| Confirmar nos menus | Enter / Espaço | A / Cross |
| Voltar nos menus | Esc | B / Circle |
| Mostrar e esconder o texto de depuração | F3 | — |
| Retirar 10 SP à personagem (só na versão de depuração) | F4 | — |

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
70 % é provisório e será afinado com a câmara e nos níveis.

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
com a câmara e nos níveis.

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
provisórios e serão afinados com a câmara e nos níveis.

### Crucifixo

Enquanto o jogador recusar os upgrades, o crucifixo é a sua única defesa. Ergue-se ao premir o
botão esquerdo do rato ou o gatilho direito do comando (RT / R2) com a personagem no chão e fica
erguido enquanto o botão estiver premido, durante no máximo 5 s. Um toque dado até 0,1 s antes de
aterrar ainda o ergue na aterragem, se o botão continuar premido, à semelhança da tolerância do
salto. Baixa quando o botão é largado, quando a personagem sai do chão ou quando os 5 s terminam.
Depois de cada uso, curto ou longo, há uma espera de 15 s até poder ser erguido de novo; um toque
dado até 0,1 s antes do fim da espera também conta.

Só um toque dado durante o jogo ergue o crucifixo. Um botão que já vinha premido, da espera, do
menu principal ou da pausa, não o ergue até ser largado e premido outra vez. Assim, o jogador
decide sempre o momento, e o clique do rato nos menus, que é o mesmo botão, nunca o ergue por
engano. Durante a pausa, o tempo de uso para.

Erguido, o crucifixo:

- abranda a personagem: a velocidade máxima desce de 720 px/s para 180 px/s (25 %);
- impede o salto. Um salto pedido com o crucifixo erguido é descartado, e não acontece quando o
  crucifixo baixa;
- afasta os demónios e as almas perdidas que estiverem a menos de 200 px; o que estiver mais longe
  não se move. As almas são empurradas para fora desse raio a 1500 px/s. Os demónios são atirados
  para longe do crucifixo, cerca de 200 px com 40 px de altura, ou só na horizontal se estiverem no
  ar, e ficam 0,3 s parados onde aterram. De muito perto, o empurrão soma-se ao arremesso enquanto
  o demónio está no raio, e ele vai parar a cerca de 300 px;
- cura 5 SP por segundo, que se somam à regeneração (ver "SP");
- acende uma luz quente cujo alcance mostra o raio do afastamento.

A duração limitada e a espera fixa obrigam a escolher quando usar a única defesa: largar o botão
cedo não poupa tempo de espera. Ao contrário do deslize na parede, o crucifixo obriga a manter o
botão premido: o esforço de o segurar faz parte da mecânica, e cada uso está limitado a 5 s. Uma
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
| Perseguir | Segue-a a cerca de 560 px/s, no chão onde está. A personagem corre a 720 px/s, pelo que fugir resulta, mas com pouca margem. |
| Aviso | Antes de cada ataque, mostra qual vem, para que o jogador tenha tempo de reagir: antes da mordida, alarga-se e baixa durante 0,2 s, sem parar de correr; antes do salto, para e encolhe durante 0,35 s. |
| Atirar-se | Salta para onde a personagem vai estar, entre 200 e 420 px, e fica 0,35 s parado onde aterra. |
| Recuar | Depois de cada ataque, afasta-se de frente para a personagem, a cerca de 400 px/s, até ficar a cerca de 130 px dela, e volta a atacar. |
| Agarrar | Segura a personagem até ela se soltar ou morrer (ver "Pancada e agarrão"). |
| Atirado | Atirado pelo crucifixo, ou pela personagem quando esta se solta, voa até aterrar. |
| Repelido | Depois de atirado pelo crucifixo, fica 0,3 s parado onde aterrou e volta a perseguir. |
| Atordoado | Depois de atirado pela personagem ao soltar-se, fica 1,2 s no chão, achatado e mais escuro, e depois recua ou volta a perseguir. |
| Fora de alcance | Com a personagem num chão ou numa parede acima ou abaixo do que os seus ataques chegam, para onde está, virado para ela, e não a segue por baixo nem por cima. Se ela descer ao seu alcance, volta a persegui-la; ao fim de 2 s, desiste e deixa-a em paz enquanto ela lá ficar. |
| Voltar | Depois de desistir, volta ao posto a passo, a 200 px/s, e retoma a ronda. Se a vir à frente pelo caminho, volta a persegui-la. |

O demónio vê a personagem a menos de 1100 px, mais de meio ecrã, se não houver uma parede entre os
seus olhos e o meio ou a cabeça dela: um muro baixo ou uma borda que tape só uma das duas não a
esconde. Só repara nela se estiver à sua frente, ou atrás a menos de 220 px (20 % do alcance), e
por isso é possível passar-lhe pelas costas. Também só começa e continua a persegui-la enquanto ele
próprio estiver no ecrã, para que nenhum demónio venha de onde o jogador não o vê; um ataque que já
começou acaba, mesmo que o demónio saia do ecrã a meio. Continua a persegui-la para lá dos 1100 px, e
desiste quando ela se afasta mais de 1600 px, quando uma parede a esconde durante 1,5 s ou quando
ele sai do ecrã. Tem dois ataques, e só ataca a personagem praticamente à mesma altura (até 24 px
de diferença):

- **Mordida.** A menos de 100 px, morde a correr: continua a persegui-la durante o aviso e morde
  onde está.
- **Salto.** A menos de 360 px, salta às vezes: a probabilidade é de 90 % por cada segundo em que a
  personagem está ao alcance, o que torna o salto legível, pelo aviso, mas não previsível. No início
  do aviso, aponta para onde ela vai estar quando ele aterrar, se mantiver a velocidade, e não muda
  de pontaria: mudar de ritmo ou de direção durante o aviso faz o salto falhar. Nunca salta para um
  buraco, nem para uma personagem que, quando ele aterrar, já lhe terá passado.

Em grupo, cada demónio decide sozinho, mas o conjunto lê-se como uma matilha:

- um demónio atrás de outro fica a 24 px dele e ataca dali, saltando-lhe por cima. Os corpos dos
  demónios não colidem entre si, para que não tremam nem se bloqueiem;
- cada um persegue e recua ao seu ritmo, até 10 % acima ou abaixo dos valores, para que nunca se
  movam em uníssono;
- sempre que fica em condições de atacar, cada um espera um tempo sorteado entre 0 e 0,5 s, para
  que não ataquem todos no mesmo instante;
- enquanto a personagem pisca, depois de uma pancada, nenhum ataca, e todos esperam a cerca de
  130 px. Esse segundo é a janela para fugir ou erguer o crucifixo. Em cinco execuções do
  `measure_demon.gd`, com 40 demónios a aproximar-se da personagem parada, só 2 ou 3 atacaram nos
  primeiros 2 s.

Todos os saltos de um demónio caem com a mesma gravidade e com o mesmo ângulo, como um salto dado
com menos força: um salto mais curto é mais baixo e mais rápido. O de 420 px sobe 32 px e dura
cerca de 0,31 s, pela conta; o de 200 px, medido pelo `measure_demon.gd` contra a personagem
parada, sobe 15,22 px (15,2 pela conta) e está de novo no chão 0,22 s depois de partir (ver "Salto
calculado a partir do desenho"). Os valores são provisórios e afinam-se a jogar.

É o desenho do nível que limita os demónios. Um demónio não sobe, não salta para cima e para à beira
de um desnível. Como nenhum salto passa dos 32 px de altura, um degrau de 48 px, uma largura da
personagem, trava-o, e uma plataforma dessa altura é um sítio seguro. Um demónio que veja a
personagem num sítio desses para onde está, virado para ela, em vez de a acompanhar por baixo de um
lado para o outro, e o jogador lê que ali não lhe chega. O mesmo vale ao contrário: um demónio numa
plataforma alta, de onde não desce, não corre até à borda para a acompanhar lá de cima. Um salto da personagem no chão do demónio
não conta, porque ela só pode voltar a descer: a perseguição continua. Quem desenha um nível sabe
assim até onde cada demónio chega, sem limites invisíveis. A exceção é o crucifixo, que pode
atirar um demónio de uma borda abaixo: o demónio cai, fica no chão onde aterra e, se vir a
personagem, persegue-a a partir daí. Quando desiste, tenta voltar ao posto, e o sítio onde a borda
ou uma parede o param passa a ser o seu posto; nunca fica a tentar subir. É uma mecânica: o jogador pode gastar o crucifixo para tirar
um demónio do caminho, e os níveis podem oferecer-lhe bordas e buracos para onde o atirar.

Os valores são os do demónio da luxúria, num ficheiro de dados (`demon/lust_demon_stats.tres`);
mudam sem alterar código e são provisórios. O aviso é, por agora, um retângulo que muda de forma e
de cor, com uma forma para cada ataque, à espera da arte e do som; a mordida precisa de uma animação
e de um som próprios. O demónio do tutorial, que fala e não persegue, terá uma cena própria
(ver "Demónio: estados, dados e famílias de personagens").

### Pancada e agarrão

Um demónio nunca mata com uma pancada: a morte vem sempre de um agarrão, a que o jogador pode
resistir. Com o SP acima do baixo, a mordida tira 10 SP e o salto 20, e a pancada atira a
personagem para trás e para cima (150 px e 40 px de altura na mordida, 250 px e 70 px no salto), sem
controlo até aterrar. A seguir, a personagem fica 1 s invulnerável, a piscar.

Com o SP baixo (25 SP ou menos), ou quando a pancada a deixaria a 0, o demónio agarra-a em vez de
lhe tirar SP. Agarrada, a personagem para logo, não corre nem salta, e o crucifixo baixa; se for
agarrada no ar, mesmo encostada a uma parede, cai a direito até ao chão. Solta-se premindo o salto
repetidamente: 8 vezes, com um demónio. Um segundo demónio pode juntar-se a meio, e pede mais
6. Com dois, o agarrão fica cheio: nenhuma pancada entra, e os outros demónios esperam a cerca de
130 px. Se o jogador parar de premir, o progresso desce: ao fim de 0,25 s sem premir, perde metade
da barra por segundo, pelo que quem prime 4 vezes por segundo não perde nada. Se não se soltar em
3 s, a personagem morre, aparece "You died" e o nível recomeça 1,5 s depois.

Durante o agarrão, a personagem e os demónios que a agarram afundam-se no chão, até 96 px, ao ritmo
do tempo que passa: o jogador vê quanto tempo lhe resta sem olhar para um número. O afundar é só
desenho, porque os corpos não se enterram, e por isso funciona em qualquer chão, mesmo numa
plataforma fina. Por agora não tem som.

Ao soltar-se, a personagem atira os demónios que a agarravam para longe (200 px, com 40 px de
altura), e cada um fica 1,2 s atordoado no chão. É a janela para fugir, e vê-se no ecrã. A
personagem fica ainda 1 s invulnerável, para não ser agarrada de novo logo a seguir.

A personagem e os demónios não se atravessam: param encostados, também a meio de um salto. A
personagem nunca fica de pé em cima de um demónio: é empurrada para o lado a 600 px/s, sem correr
nem saltar até pisar outra coisa. Assim, a cabeça de um demónio, onde a mordida não chega, nunca é
um sítio seguro.

Os valores estão em `player/grab_stats.tres` (o agarrão), no ficheiro de dados dos demónios (o dano
e os arremessos) e na cena da personagem (a invulnerabilidade), e são provisórios. Soltar-se
mantendo o salto premido, em vez de o premir repetidamente, já existe no código e chega às opções
numa tarefa seguinte, para quem não consegue premir depressa.

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
- Os valores ainda serão afinados, com a câmara e depois nos níveis. Após cada afinação, as medidas
  voltam a ser obtidas com o `measure_movement.gd` (ver "Testes e medidas").
- Os níveis podem vir a ser construídos com tiles ou com cenário pintado. Quando o tamanho do tile
  for definido, estas medidas serão convertidas em tiles.

## Câmara

A câmara segue a personagem com técnicas descritas por Keren (2015), escolhidas para as situações
deste jogo: a corrida, as chaminés, as subidas e as quedas. As medidas foram obtidas nos testes, a
60 passos de física por segundo, num ecrã de 1920×1080.

| Técnica | Comportamento | Medida |
|---|---|---|
| Janela | a câmara só se desloca quando a personagem sai de um retângulo à volta do ponto que segue: 64 px para cada lado, 250 px acima e nenhum abaixo | um salto completo (240 px) e o balanço numa chaminé de 120 px (72 px) não movem a câmara |
| Suavização | em cada passo, a câmara percorre uma fração da distância que falta, independente da frequência de imagem | 95 % da distância em 0,5 s |
| Antecipação | a câmara mostra 300 px a mais do lado para onde a personagem corre e só troca de lado depois de a personagem recuar 180 px a partir do ponto mais afastado | em corrida, 1,5 s de percurso visível à frente; a troca de lado conclui-se em cerca de 1,2 s, sem ultrapassar a posição final |
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

Os valores da câmara estão no ficheiro `camera_stats.tres`, em `Projeto/camera/`, e editam-se no
Inspector do Godot, como os do movimento.

| Campo no Inspector | Valor atual | O que controla |
|---|---|---|
| Window Half Width | 64 px | a largura da janela para cada lado do ponto seguido |
| Window Up | 250 px | a altura da janela acima do ponto seguido; o salto completo e 10 px de margem |
| Edge Margin | 0,17 | a distância mínima do corpo da personagem às bordas do ecrã, em fração do ecrã, antes de a câmara a acompanhar de imediato; com 0, só fica a regra do corpo inteiro no ecrã |
| Window Down | 0 px | a altura da janela abaixo do ponto seguido; com 0, a câmara acompanha logo qualquer descida |
| Follow Sharpness | 6 /s | a rapidez da suavização |
| Look Ahead Distance | 300 px | a distância da antecipação |
| Turn Threshold | 180 px | o recuo necessário para a antecipação trocar de lado; acima dos 174 px de balanço na chaminé mais larga que se sobe apenas com o salto |
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

## Fundo em camadas

O fundo de cada nível é formado por camadas a distâncias diferentes da câmara. Quanto mais distante a
camada, mais devagar se desloca no ecrã (efeito de parallax), o que dá profundidade ao cenário sem
desenhos adicionais. Na sala de teste, a camada distante desloca-se 0,25 px por cada pixel que a
câmara percorre e cobre o ecrã em qualquer ponto da sala, tanto nos ecrãs 16:9 como nos 21:9.

O fundo de cada nível parte do modelo `background/level_background.tscn`, que já contém as quatro
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
2. Abrir o fundo do nível, em `Projeto/background/`. Um nível novo cria o seu com Scene › New
   Inherited Scene a partir de `level_background.tscn` e coloca-o como primeiro nó da cena do nível,
   para ficar atrás de tudo; a sala de teste usa `test_room_background.tscn`.
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
`player/` do projeto Godot (`Projeto/player/` no repositório). Abre-se no painel FileSystem
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

Os valores do crucifixo estão no ficheiro `crucifix_stats.tres`, na pasta `crucifix/`, e editam-se
da mesma forma. O Speed Multiplier e o Repel Radius aplicam-se de imediato, também com o jogo a
correr, quando são mudados no separador Remote do editor; os restantes valores são lidos sempre que
são usados.

| Campo no Inspector | Valor atual | O que controla |
|---|---|---|
| Speed Multiplier | 0,25 | a fração da velocidade máxima que se mantém com o crucifixo erguido |
| Raise Buffer Time | 0,1 s | o tempo durante o qual um toque fica guardado enquanto o crucifixo não se pode erguer, como antes de aterrar ou no fim da espera (0 desliga) |
| Max Use Time | 5 s | o tempo máximo de cada uso |
| Cooldown Time | 15 s | a espera depois de cada uso, qualquer que tenha sido a sua duração |
| Repel Radius | 200 px | a distância à qual os demónios e as almas perdidas são afastados, e o alcance da luz |
| Repel Speed | 1500 px/s | a velocidade a que são empurrados para fora desse raio |
| Heal Per Second | 5 SP/s | a cura por cada segundo com o crucifixo erguido |

Os valores dos SP estão no ficheiro `soul_points_stats.tres`, na pasta `player/`. O Max SP e o Low
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
    ├── core/          serviços globais: as opções do jogador (autoload Settings), o registo moral (autoload Moral) e os perfis de controlos
    ├── player/        personagem: cena, scripts, valores do movimento, SP e agarrão
    ├── crucifix/      crucifixo: cena, script e valores
    ├── demon/         demónios que perseguem: cena, scripts e os valores de cada nível
    ├── camera/        câmara do jogo e zonas de câmara
    ├── debug/         overlay de depuração
    ├── levels/        salas, níveis e a entrada de cada nível na lista do menu (LevelEntry)
    ├── background/    fundo em camadas: as camadas (BackgroundLayer), o modelo e o fundo de cada nível
    ├── ui/            menus, ecrã das opções e o tema comum (ui_theme.tres)
    ├── components/    componentes usados por mais de um sistema: Repellable, Hitbox, Hurtbox e SinkingDrawing
    ├── tests/         testes e medidas que correm sem janela
    │   └── support/   preparação comum aos testes
    └── assets/        sprites, audio, fonts
```

O projeto organiza-se por sistema: cada pasta reúne a cena, os scripts e os ficheiros de dados
(`.tres`) de uma parte do jogo, que se encontram assim num único local. É a organização que a
documentação do Godot descreve como a mais comum, com os recursos junto das cenas que os usam
([Project organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)).
Um sistema novo, como um demónio ou um menu, recebe a sua pasta. Os ficheiros movem-se e
renomeiam-se no painel FileSystem do editor, que atualiza as referências entre cenas e recursos; no
fim, uma pesquisa pelo caminho antigo em todo o projeto confirma que nenhum script, incluindo os
testes, ficou a apontar para ele.

Para que a organização se mantenha à medida que o jogo cresce, seguem-se quatro regras:

- `components/` recebe apenas o que dois ou mais sistemas usam; o resto fica na pasta do sistema a
  que pertence.
- O que é global e não pertence a nenhum sistema, como o estado do jogo, as opções gravadas ou o
  áudio, fica numa pasta `core/`, criada quando surgir o primeiro desses serviços.
- A arte e o som seguem uma única convenção, decidida com a primeira entrega: junto do sistema que
  os usa, ou em `assets/` com as mesmas subpastas dos sistemas. As duas não se misturam.
- Um sistema não acede ao interior de outro: comunica por sinais ou por uma referência atribuída no
  Inspector, nunca por um caminho na árvore de nós.

A pasta `tests/` fica à parte, para que a exportação a possa excluir de uma só vez.

Para um nível aparecer no Play, acrescenta-se à lista Levels do Main, no Inspector do `main.tscn`
(Add Element › New LevelEntry, com o título e a cena). A ordem da lista é a dos botões. Um elemento
deixado vazio, ou sem cena, fica fora do menu, com um aviso no Output.

O nó raiz de cada nível tem o script `levels/level.gd` (`Level`), com a personagem do nível no campo
Player do Inspector. Quando a personagem morre, este script espera 1,5 s, para que a morte se veja,
e recomeça o nível: no jogo, o Main troca-o por uma cópia nova da mesma cena; aberto com F6, o nível
recarrega-se a si próprio. Uma cópia nova repõe a personagem, os demónios e a câmara como no início,
sem que cada sistema precise de código para se repor. Um nível sem este script não recomeça.

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
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_signals.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_debug_overlay.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_game_camera.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_window.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_look_ahead.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_vertical.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_landed_signal.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_zones.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_input.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_keeps_player_on_screen.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_main_flow.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_pause.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_phase_exit.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_settings.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_options.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_menus.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_input_profiles.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_controls.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_background_layer.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_soul_points.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_hit_boxes.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_knockback.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_grab_rules.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_grab_escape.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_block.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_sinking_drawing.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level_restart.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_moral_record.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_moral_dialogue.gd
```

O `test_input_profiles.gd` escreve seis ERROR, das tentativas de atribuir teclas inválidas, todos
esperados. O `test_soul_points.gd` escreve quatro ERROR, das quantidades de dano e de cura
inválidas, também esperados. O `test_moral_record.gd` escreve seis WARNING, de uma tentação
desconhecida (aceite e consultada), de um tom desconhecido e de três tempos de escuta inválidos,
igualmente esperados.

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
gravação). O caso do ficheiro estragado do `test_settings.gd` escreve um ERROR e um WARNING, ambos
esperados.

O `measure_movement.gd` não verifica resultados: imprime as medidas da secção "Medidas para o
desenho de níveis", com os valores que estiverem no `.tres`. As medidas junto das bordas correm a
partir de 12 pontos de partida, 1 px entre cada um, que cobrem um passo de física à velocidade
máxima, e imprimem o menor e o maior valor.

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_movement.gd
```

O `measure_crucifix_repel.gd` também não verifica resultados: mede quanto custa, num passo de
física, a lista do que está dentro do raio do crucifixo, com 10, 50 e 200 demónios de substituição,
em chamadas seguidas e no pior caso, e compara esse custo com o limite de 0,05 ms. Os números e a
decisão estão em "Crucifixo: componentes e modificadores de movimento".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_crucifix_repel.gd
```

O `measure_soul_points.gd` também não verifica resultados: aplica um golpe que deixa a personagem
com 20 SP e mede, com os valores do `soul_points_stats.tres` e com quatro regenerações de
comparação, o tempo até sair do SP baixo e até encher, e os SP recuperados nos 3 s a seguir à
pausa. Imprime também o que o crucifixo cura durante a pausa. Os números citados em "SP" vêm daqui.

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_soul_points.gd
```

O `measure_demon.gd` também não verifica resultados: mede quanto acrescentam a cada passo de física
10, 50 e 200 demónios a perseguir a personagem, em média e no pior passo, e compara o custo de 50 com
os limites de 1,5 ms em média e 2 ms no pior passo. Cada parte começa com uma personagem nova, porque
os demónios lhe gastam o SP e, sem um nível que recomece, uma personagem morta num agarrão ficava
presa até ao fim. Os números e a decisão estão em "Demónio: estados,
dados e famílias de personagens".

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_demon.gd
```

### A personagem por dentro

A cena é `player/player.tscn`, com o script `player/player.gd`: um `CharacterBody2D` com uma
caixa de colisão de 48 × 96 px e a origem nos pés, pelo que, num nível, a origem fica na linha do
chão. Está na camada `player` e colide com `world`, `one_way_platform` e `enemy`. Os valores vêm de um
recurso `PlayerMovementStats` (`player/player_movement_stats.gd`), guardado em
`player/player_movement_stats.tres`.

O desenho é um `Sprite2D` com uma imagem provisória, feita a partir do desenho de conceito
(`assets/sprites/player/player_concept.png`): uma célula de 192 × 192 px, com os pés na linha
y = 184, ao centro, e o corpo do tamanho da caixa de colisão (43 × 96 px). O sprite fica em (0, −88),
o que põe os pés na origem. As animações vão substituir esta imagem, com a mesma célula e a mesma
linha dos pés.

A personagem não lê o teclado diretamente. Um nó filho, `PlayerInput` (`player/player_input.gd`), é
o único que lê as ações da personagem no Input Map, e responde em cada passo de física a cinco
perguntas: a direção da corrida e, para os botões de saltar e do crucifixo, se acabaram de ser
premidos e se continuam premidos. A personagem recebe
este nó pelo Inspector, no campo Input. Uma inteligência artificial, uma cena animada ou um teste
controlam a personagem colocando nesse campo outro nó que estenda `PlayerInput`, sem alterar o
movimento. É o primeiro passo do padrão Component descrito por Nystrom (2014, capítulo
"Component"), que separa a entrada do resto do objeto. Quando existirem, a pausa, o diálogo e a
assistência de salto completo poderão atuar nesse único ponto. O `test_player_input.gd` verifica que, com um desses nós, a personagem corre,
salta, completa o salto e se encosta à parede sem nenhuma tecla premida, e que as teclas deixam de
ter efeito.

A lógica organiza-se numa máquina de estados com três estados, definida por um `enum` no
`player.gd`: no chão (`ON_FLOOR`), no ar (`IN_AIR`) e na parede (`ON_WALL`). Cada estado tem a sua
função de física, e o estado só muda em `_update_state()`, no início de cada passo de física, a
partir do resultado do último `move_and_slide()`. O chão tem prioridade. Para entrar no estado da
parede é preciso empurrar a personagem contra ela, mas para permanecer nele não, pelo que o estado
termina quando a personagem deixa de tocar na parede ou aterra. Preferiu-se o `enum` a um nó por
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
e o mesmo valor deixa a câmara a 81 px da personagem em corrida, contra 144 px sem interpolação. A
câmara do jogo faz a sua própria suavização, uma vez por passo.

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
| `crucifix` | botão esquerdo do rato | RT / R2 (eixo 5) |
| `pause` | Escape | Start |
| `toggle_debug_overlay` | F3 | — |
| `ui_accept` | Enter, Espaço | A / Cross |
| `ui_cancel` | Escape | B / Circle |

O `ui_accept` e o `ui_cancel` são ações que o Godot já traz para os menus; acrescentou-se-lhes o A e o
B do comando, que não tinham.

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
golpe é detetado uma vez, de um só lado.

A camada `camera_bounds` é a das zonas de câmara (`CameraZone`): retângulos que limitam o que o ecrã
mostra enquanto a personagem está dentro deles. As zonas não detetam colisões; a câmara lê-lhes a
geometria, e a camada serve para as identificar e desenhar no editor.

A camada `repellable` é a da cena `components/repellable.tscn`, que se coloca em tudo o que o
crucifixo afasta. A camada está definida na cena, no Inspector, e não no código. O crucifixo procura
apenas nessa camada, pelo que um demónio ou uma alma só é afastado se tiver o componente.

A camada `enemy` é a do corpo dos demónios, que colide com `world`, `one_way_platform` e `player`.
Os demónios atravessam-se uns aos outros, para que não tremam nem se bloqueiem. A personagem e os
demónios não se atravessam: param encostados, e a personagem nunca fica de pé em cima de um
demónio (ver "Pancada e agarrão"). Um demónio que caia de uma borda em cima da personagem, ou dois
demónios dos dois lados, podem encurralá-la; é intencional, porque encostar a um demónio é ficar ao
alcance da mordida, e vigia-se nos playtests.

#### Crucifixo: componentes e modificadores de movimento

O crucifixo foi construído para não criar dependências entre sistemas, com padrões comuns na
indústria:

- **Componente** (Nystrom, 2014, capítulo "Component"). O crucifixo é uma cena própria
  (`crucifix/crucifix.tscn`), filha da personagem. Lê o botão através do mesmo `PlayerInput` da
  personagem, pelo que uma inteligência artificial, uma cena animada ou um teste também o controlam.
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
  habitual nas habilidades. Isto resolve, sem estado extra, os botões que já vinham premidos da
  espera, do menu principal ou da pausa: nenhum deles é um toque novo. Para um toque dado um pouco
  cedo não se perder, fica guardado durante o Raise Buffer Time, à semelhança da tolerância do
  salto.
- **Máquina de estados com tempos em passos de física.** O crucifixo tem três fases: pronto,
  erguido e em espera (`READY`, `RAISED`, `COOLDOWN`). O tempo de uso, a espera e a tolerância
  contam-se em passos de física inteiros, como as tolerâncias do salto, para que os testes os
  verifiquem ao passo exato. Os sinais `cooldown_started` e `cooldown_finished`, e o tempo restante
  de cada fase, servem o HUD.
- **Componente `Repellable`** (`components/repellable.tscn`), à semelhança dos *hitboxes* e
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

Com o resto do jogo, o crucifixo comunica por sinais (`raised`, `lowered`, `cooldown_started`,
`cooldown_finished`, `lost` e `healed`), que o HUD e o som poderão escutar e que os SP já escutam
(ver "SP: componente, dados e ligação ao crucifixo").
Perdido, emite `lost` e sai do jogo (`queue_free`); o HUD retira o ícone ao receber esse sinal. A
exceção é o afastamento: o crucifixo empurra os demónios e as almas chamando o componente
`Repellable` de cada um (ver acima), sem conhecer os seus scripts.

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
cedo, a parede, a saída do chão, a duração máxima, a espera fixa, a pausa, a perda, a cura, o
afastamento, a camada da cena `Repellable` e a afinação com o jogo a correr. Usa um demónio de
substituição, que flutua à altura do crucifixo; o afastamento de um demónio no chão verifica-se no
`test_demon.gd`, com o crucifixo da personagem. O `test_crucifix_menus.gd` usa a cena principal
e o rato: com o botão premido durante a pausa e mantido ao retomar com Esc, com um clique no Resume
e com o botão premido desde o menu principal, o crucifixo não se ergue até o botão ser largado e
premido de novo no jogo.

#### SP: componente, dados e ligação ao crucifixo

Os SP são um nó-componente, `SoulPoints` (`player/soul_points.gd`), filho da personagem, com os
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

O crucifixo cura através de uma ligação na cena da personagem: em `player/player.tscn`, o sinal
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
`demon/demon.tscn`, com os valores num `Resource`, `DemonStats`, como o movimento, o crucifixo e os
SP. Cada ataque é outro `Resource`, `DemonAttack`, e o `DemonStats` tem a lista dos ataques do
demónio. Os do nível 1 estão em `demon/lust_demon_stats.tres`; os demónios de um nível novo são
outro ficheiro com os mesmos campos, outros ataques e outra arte, sem código novo.

As personagens dividem-se pelo que fazem, e não pela história: as que perseguem usam esta cena, e as
que estão paradas e falam (o demónio do tutorial, as almas e os bosses) terão cenas próprias. O que
as duas famílias partilham são componentes, como o `Repellable`, e não uma classe-mãe. Uma
classe-mãe comum ficaria quase vazia e não serviria uma personagem das duas famílias, como uma alma
que fala e que o crucifixo afasta. Pela mesma razão, o demónio do tutorial, que fala e não persegue,
não é esta cena com a perseguição desligada.

- **Máquina de estados num só script.** Os doze estados (`IDLE`, `CHASE`, `WARNING`, `LUNGE`,
  `RETREAT`, `GRAB`, `THROWN`, `REPELLED`, `STUNNED`, `RETURN`, `OUT_OF_REACH` e `PATROL`) são uma
  enumeração no `demon.gd`, o mesmo padrão da personagem, que o grupo já conhece. A alternativa, um
  nó e um script por estado, pagaria já por estados que ainda não tinham design. Com a ronda e o
  "fora de alcance", o `demon.gd` tem 825 linhas, e o desenho do nível 1 pede ainda o alerta e a
  procura. Antes deles, cada estado passa a ser um objeto próprio: é o passo seguinte (ADR 0033).
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
- **Sentidos num componente.** O que o demónio percebe da personagem está no `DemonSenses`
  (`demon/demon_senses.gd`): uma área circular, do raio do Sight Distance, encontra-a, e um raio
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
  quem não distingue as cores.
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
- **Pancada e agarrão em componentes.** O ataque passa por dois componentes de `components/`: a
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
  `test_grab_escape.gd`, antes da correção).
- **Matilha sem coordenador.** Cada demónio decide sozinho, com uma área que encontra os outros
  demónios à sua frente, um sorteio próprio da espera antes de atacar e velocidades próprias. Um nó
  que distribuísse a vez de atacar garantia que nunca atacam dois ao mesmo tempo, mas tirava pressão
  e mudava a dificuldade; fica para o caso de os playtests mostrarem que o sorteio não chega. Quando
  o agarrão está cheio, a `Hurtbox` fecha-se, um estado separado da invulnerabilidade, para que
  nenhuma pancada entre sem que a personagem pisque. O demónio guarda a `Hurtbox` da personagem ao
  começar a persegui-la e não ataca enquanto ela não aceita pancadas.
- **A personagem antes dos demónios.** No Godot, cada corpo vê os outros onde eles estavam no
  início do passo. Com a personagem e o demónio a colidir, isso deixava o demónio entrar no espaço
  que a personagem acabara de ocupar, e os dois tremiam 2 px a empurrar-se. A personagem tem por
  isso uma prioridade de física mais baixa (Process Physics Priority −1), e move-se antes dos
  demónios em cada passo.
- **Afundar com um shader.** O afundar corta o desenho na linha dos pés, com um shader
  (`components/sink.gdshader`) que o componente `SinkingDrawing` controla. Mover os corpos para
  baixo exigia, em todos os níveis, um chão com pelo menos 96 px de espessura onde um demónio
  agarra, e numa plataforma fina a personagem saía por baixo. O valor do shader não passa pela
  physics interpolation, que só move posições, por isso o desenho volta ao sítio no próprio passo
  em que a personagem se solta. Cada demónio tem o seu material, e um a afundar não afunda os
  outros.
- **Recomeçar a sala.** Quando a personagem morre, o nível é substituído por uma cópia nova da sua
  cena (ver "Estrutura"). Repor cada sistema à mão (a personagem, os SP, os demónios, a câmara)
  pedia código de reposição em todos eles, e cada sistema novo podia esquecê-lo; a cópia nova está
  sempre como no início, e por isso cada demónio recomeça no seu posto.
- **Posto e regresso.** O posto é a posição horizontal onde o nível pôs o demónio. Com Return Speed
  acima de 0, quem desiste volta lá a passo; a 0, fica onde desistiu, como antes. Se o fim do chão
  ou uma parede o parar pelo caminho, como depois de o crucifixo o atirar para outro chão, esse
  sítio passa a ser o posto. A alternativa, tentar voltar e ficar à borda, deixava-o parado de
  frente para um chão a que nunca chega, precisamente o que o desenho do nível 1 quer acabar. Só
  contam as paredes do mundo (corpos estáticos e tiles): o corpo da personagem, que se move, faria
  de um sítio livre um posto para sempre. Num nível, um posto fica a mais de 30 px de uma borda,
  o alcance do raio que procura o chão; mais perto, o demónio para antes e o posto muda um pouco.
- **Fora de alcance e ronda (ADR 0033).** Antes, um demónio que via a personagem num degrau alto
  corria até ficar por baixo dela e acompanhava-a de um lado para o outro, e sem ninguém à vista
  ficava imóvel, como se estivesse desligado. O alcance não é um valor novo: é a maior diferença de
  altura dos seus ataques (hoje 24 px), para que os dois números nunca se contradigam. A personagem
  conta acima e abaixo do demónio, e só com o demónio no chão: um demónio a cair ainda está a
  chegar ao seu chão. A personagem
  só fica fora de alcance quando está num chão, ou a deslizar ou agarrada a uma parede: no ar, ou a
  roçar uma parede a subir, só pode voltar a descer, e um salto para fugir nunca para a perseguição
  nem corta uma mordida a meio. Depois de desistir, o demónio ignora-a enquanto ela estiver acima do
  seu alcance; sem isso, voltava a vê-la no passo seguinte e recomeçava a perseguição de 2 em 2 s. Para voltar a perseguir basta que ela desça ao
  alcance, mesmo no ar; esta diferença entre a regra de entrada e a de saída evita que o demónio
  pare e arranque aos solavancos com a personagem numa chaminé. A ronda é um estado próprio
  (`PATROL`), e o parado (`IDLE`) passa a ser também a pausa nas pontas, para que a arte tenha uma
  animação para andar e outra para estar parado. Cada demónio sorteia as suas pausas, e por isso
  dois demónios postos lado a lado depressa deixam de andar ao mesmo ritmo. Em ronda, os demónios
  não guardam distância entre si: dois troços sobrepostos deixam-nos atravessar-se. Por isso é uma
  regra do desenho dos níveis que os troços de dois demónios no mesmo chão não se sobreponham, e o
  teste das regras dos níveis, a fazer com o gerador do nível 1, vai verificá-la. Com Patrol Width a 0, o demónio fica parado no posto,
  como antes. Fora do ecrã, não anda, para que o jogador encontre cada demónio perto de onde o nível
  o pôs e para que os demónios que não se veem custem o mínimo.

Antes de decidir se a perseguição precisava de ser otimizada, fixaram-se dois limites para 50
demónios a perseguir ao mesmo tempo, muitos mais do que um ecrã terá: um limite para a média por
passo de física, um pouco acima do medido, para que um aumento de custo se note cedo, e 2 ms no pior
passo, a parte de um passo de 16,6 ms que um sistema pode ocupar. Mede-se com o `measure_demon.gd`,
com todos os demónios a ver a personagem parada e a persegui-la: um de cada vez ataca, e os outros
esperam enquanto ela pisca, o caso mais exigente que o jogo permite. Cada parte da medida começa com
uma personagem nova, com o SP cheio, para que nenhum agarrão a deixe presa a meio. O custo é o que
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
perseguição a meio do regresso, o posto novo noutro chão e contra uma parede. Com o "fora de
alcance", verifica que o demónio para virado para a personagem num degrau alto e não a segue
quando ela anda por cima, que numa plataforma alta não corre até à borda por ela estar em baixo, que volta a persegui-la quando ela desce ao alcance, ainda no ar, que
desiste ao fim do tempo mesmo vendo-a e depois a deixa em paz enquanto ela lá ficar, que um salto
dela no seu chão não para a perseguição e que não avisa de um ataque a uma personagem no ar acima do
seu alcance. Com a ronda, verifica o vai
e vem dentro da largura e à velocidade certas, as pausas dentro dos limites, a volta à beira de um
desnível e contra um degrau, a paragem fora do ecrã, as pausas diferentes de dois demónios, a
perseguição a meio da ronda e a ronda retomada depois do regresso ao posto. O caso do degrau mudou:
antes, o demónio corria até ao degrau; agora para onde a vê. São 105 casos. Todos menos os seis
últimos usam valores próprios, pelo que afinar o `.tres` não os altera. Os seis últimos leem o
`.tres` do nível 1 e
confirmam o que o desenho dos níveis assume: cada ataque com uma das animações da arte, os saltos e a diferença
de altura para atacar abaixo de um tile (48 px), o Lose Distance acima do Sight Distance e a
perseguição mais lenta do que a corrida da personagem, e a regra do ecrã ligada, a visão de pelo
menos meio ecrã, menos alcance para trás do que para a frente e o regresso mais lento do que a
perseguição, para que um demónio a voltar nunca pareça vir na direção dela, e a ronda ligada e mais
lenta do que a perseguição, com um degrau de um tile fora do alcance.

#### Overlay de depuração

Para afinar o movimento durante o jogo, a sala de teste mostra no canto superior esquerdo os FPS e
o passo de processamento e o de física mais lentos do último segundo, valores que o Godot só
atualiza uma vez por segundo, pelo que um único frame lento permanece visível durante um segundo.
Mostra também o estado e a velocidade da personagem e, depois de cada salto, o tipo de salto, as
tolerâncias usadas, em passos de física, e a altura atingida. Um salto completo mostra
240 px, o mesmo valor que os testes medem. Com a câmara ligada, mostra ainda a zona de câmara em que
a personagem está e as distâncias atuais da antecipação e do olhar para baixo. Mostra ainda os SP,
a velocidade atual da regeneração e se os SP estão baixos ou acabaram. A tecla F3 mostra e esconde
o texto.

A tecla F4 retira à personagem o valor Debug Damage do overlay (10 SP, no Inspector), como um golpe,
para experimentar a regeneração e os avisos antes de haver demónios. Cada toque conta uma vez,
mesmo com a tecla premida, não atua com o jogo em pausa e funciona com o texto escondido. O overlay
pode ferir a personagem diretamente porque não faz parte do jogo: é uma ferramenta de depuração,
ligada à personagem num só sentido, e sai das exportações de release, pelo que nada no jogo depende
dele. O F4 está reservado nos perfis de controlos, como o F3, porque uma ação do jogo atribuída a
essa tecla feriria a personagem sempre que fosse usada nas versões de depuração.

O overlay é uma cena própria, `debug/debug_overlay.tscn`, num `CanvasLayer`, pelo que não se
desloca com a câmara. Recebe a personagem pelo Inspector e lê-a, ou fere-a com o F4, sem que ela
dependa dele, pelo que a personagem é testada e exportada sem o overlay. Continua ativo com o jogo
em pausa e, nas exportações de release, remove-se a si próprio, e o F4 com ele. O
`test_debug_overlay.gd` verifica o comportamento nas versões de depuração; a remoção na versão de
release só poderá ser confirmada na primeira exportação.

#### Câmara

A câmara (`camera/game_camera.tscn`, script `GameCamera`) é uma `Camera2D` colocada ao lado
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

#### Fundo em camadas

O fundo é feito de nós `BackgroundLayer` (`background/background_layer.gd`), uma extensão do
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
  `components/color_ramp.gdshader` e atribui-o a todas as peças sem material próprio, incluindo as
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
| 2 | plano de jogo: tiles, peças, personagem, demónios | nós seguintes do nível, com Z Index 0 |
| 3 | camada Front do fundo | Z Index 10 |
| 4 | interface e overlay de depuração | `CanvasLayer`, por cima de tudo |

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
sem escurecer. O `test_phase_exit.gd` verifica as duas situações.

A pausa usa `get_tree().paused`. O Main corre sempre (Process Mode Always) e só o `LevelSlot` é
Pausable: o nível para e o Main continua a receber o Esc. O overlay de depuração continua ativo, e o
mesmo acontece a qualquer nó de um nível com Process Mode Always. Perder o foco da janela também pausa
(Main › Pause On Focus Loss), opção que convém desligar quando se afinam valores pelo separador
Remote do editor.

O Espaço e o A servem para saltar e para confirmar nos menus, e o B para interagir e para voltar. Os
botões do Godot disparam quando a tecla é largada, e o B fecha a pausa também ao ser largado. Isso
não chega: num toque rápido, carregar e largar chegam no mesmo frame, e o Godot considera a ação
acabada de carregar durante todo esse frame. Por isso o jogo retoma no frame seguinte ao da tecla que
o retomou. Os testes confirmam que retomar com o Espaço, o A ou o B, também num toque rápido, não faz
saltar nem interagir; com o jogo a retomar no próprio frame, a personagem saltava.

As opções (volume dos buses Master, Music, SFX, Ambience e UI, ecrã inteiro, V-Sync, limite de FPS
e controlos)
estão no autoload `Settings`, porque têm de estar aplicadas antes de qualquer
cena. Gravam-se em `user://settings.cfg` (no Windows, `%APPDATA%\Godot\app_userdata\P2D\`), um
ficheiro de texto legível, com número de versão. Um ficheiro em falta ou ilegível, ou com valores de
tipo errado, fora do intervalo ou que não são números, dá os valores predefinidos. O limite de FPS só
limita o desenho; a física mantém-se nos 60 passos por segundo. Os menus nunca alteram o áudio, a
janela ou o motor diretamente: pedem a mudança ao `Settings`, que a aplica e grava. Com o jogo
embutido no editor, o ecrã inteiro não se aplica (só a janela normal é suportada); experimenta-se com
o jogo numa janela à parte ou numa exportação.

#### Controlos: perfis e remapeamento

Os controlos seguem o modelo habitual nos jogos de PC: perfis predefinidos, um perfil personalizado
e remapeamento por captura da tecla seguinte.

- Os perfis só mudam o teclado e o rato das ações de jogo (andar, saltar, crucifixo, interagir). O
  comando, a pausa, o overlay de depuração e as ações dos menus ficam como o `project.godot` os
  define.
- Cada tecla está definida num único sítio. O perfil predefinido é o Input Map do `project.godot`,
  lido nas definições do projeto: uma tecla acrescentada em Project Settings ▸ Input Map passa a
  fazer parte dele. O perfil das setas está definido uma só vez, em `core/input_profiles.gd`, e deixa
  W, E, A, S e D livres para os upgrades. O Custom começa como cópia do predefinido.
- O `Settings` guarda o perfil escolhido e as teclas do perfil personalizado e aplica-os ao Input
  Map. Como nenhum script lê teclas diretamente, a personagem e o crucifixo não mudaram.
- No ecrã Controls (`ui/controls_menu.gd`), carregar no botão de uma ação do perfil Custom faz o
  ecrã esperar pela próxima tecla ou botão do rato. O Esc ou o B cancelam sem alterar nada. A espera
  apanha a tecla antes de qualquer outro nó, pelo que o Esc não fecha a pausa.
- Conflitos: se a tecla escolhida pertencia a outra ação, essa ação perde-a e, se ficar sem
  nenhuma, recebe as teclas antigas da primeira (troca). Nenhuma ação fica sem tecla. Preferiu-se a
  troca a um aviso de conflito, porque não deixa o jogador num estado em que uma ação não funciona.
- O `settings.cfg` guarda o perfil pelo seu identificador (por exemplo `arrows_and_qweasd`) e cada
  tecla como texto legível, com o nome da tecla ou do botão (por exemplo `key:Q`, `key:Ctrl` ou
  `mouse:left`), e nunca como números nem como objetos do Godot. Assim, o ficheiro lê-se e corrige-se
  à mão, acrescentar ou reordenar perfis não troca o perfil de quem já o tinha escolhido, e um
  ficheiro alterado à mão não cria objetos arbitrários. Um perfil ou uma tecla inválidos dão os
  valores predefinidos. O botão Reset to defaults das opções não mexe nos controlos; o ecrã Controls
  tem o seu próprio Reset.
- O `Settings` só altera uma ação no Input Map quando as teclas mudam: retirar uma tecla a uma ação
  solta essa ação, o que largaria uma tecla que o jogador estivesse a premir.
- Nos testes, o `Settings` guarda as opções só em memória e não lê nem escreve o ficheiro do
  jogador (`GameSettings.ignore_player_file`, ver "Testes e medidas").

O tamanho da letra e os espaços entre elementos estão num único tema, `ui/ui_theme.tres`, e nenhum
nó define o seu próprio tamanho de letra: uma futura opção de tamanho do texto altera apenas o tema.

#### Registo moral: escondido, uma soma e dois limiares

O jogo julga o homem pela forma como se joga, sem o mostrar. O autoload `Moral` guarda esse registo
num único sítio, e nada no ecrã o lê. As falas (ficheiros `.dialogue`) e as ofertas dos demónios
comunicam com ele apenas por seis nomes: aceitar uma tentação, o tom de uma resposta (humilde ou
arrogante), o tempo que o homem ouviu uma proposta antes de a recusar, se já aceitou uma dada
tentação, o estádio atual e o aviso de que o estádio mudou.

Tudo o que o homem faz soma pontos a um único total. Uma tentação aceite soma o valor indicado para
ela, contando uma só vez, mesmo que volte a ser aceite. Cada portagem roubada no nível 3 vale menos
do que um atalho, porque esse nível tem três. Uma resposta arrogante soma pouco. Ouvir uma proposta
só conta a partir de alguns segundos, e cada proposta tem um máximo; ouvida outra vez, por exemplo
depois de recomeçar a fase, conta apenas a escuta mais longa. Dois limiares transformam o total no
estádio 0, 1 ou 2, que escolhe a variante das falas do homem: quanto mais alto, pior ele fala.
Cada resposta conta sempre que é dada. Por isso, uma conversa com respostas não se repete quando a
fase recomeça; essa regra pertence ao estado do jogo (`GameState`), que guarda as conversas já
ouvidas, e não ao registo moral.

Uma resposta humilde fica contada, mas não retira pontos, e o total nunca desce. Se descontasse, o
jogador poderia aprender por tentativa e erro a "limpar" a fala com respostas humildes, e o registo
deixaria de medir o que o jogador escolhe. A soma única foi preferida a contar apenas as tentações,
que ignoraria a soberba nas respostas, e a ter um limiar por categoria, que daria seis valores
difíceis de afinar e de explicar.

| Valor (`core/moral_stats.tres`) | Referência |
|---|---|
| Atalho ou dom de um demónio | 1 ponto |
| Cada portagem roubada | 0,4 pontos |
| Resposta arrogante | 0,15 pontos |
| Ouvir uma proposta | 0,1 pontos por segundo além de 3 s, até 0,5 por proposta |
| Estádio 1 / estádio 2 | a partir de 1 / de 3 pontos |

São valores de referência, a afinar em jogo. Com eles, um atalho basta para a fala piorar, e as
três portagens juntas pesam pouco mais do que um atalho. As regras estão numa classe sem nós
(`MoralRecord`), testada isoladamente; o autoload limita-se a disponibilizá-la. O `reset()` limpa o
registo para um jogo novo; a gravação fica para quando houver saves.

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

## Licença

Ver [LICENSE](LICENSE).

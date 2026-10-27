# Nível 1 (luxúria): desenho das três fases

Este documento define o desenho do espaço e dos cães das três fases do nível 1, refeito depois do
pitch. Serve de referência a quem constrói as salas e de critério para as rever: a secção 11 é a
lista de verificação que cada sala tem de cumprir. Nos termos usados, os "cães" são os demónios da
luxúria e "o homem" é a personagem jogável. Cada regra indica entre parênteses a fonte em que se
apoia; as fontes, o que se leu de cada uma e onde se encontram estão na secção Referências.

## 1. Motivo da revisão

Na apresentação do pitch, os docentes criticaram sobretudo o nível 1:

- as três fases parecem independentes, feitas por pessoas diferentes, sem uma lógica comum;
- o nível deve ser pensado em função dos cães, dos saltos e do crucifixo, e não das plataformas e dos
  picos;
- os espaços são demasiado abertos: devem ser fechados, como grutas, com a câmara a mostrar sempre o
  chão e o teto e quase nenhuma área de ecrã sem jogo.

As cenas existentes confirmam a crítica:

| Fase | Cena | Dimensão | Conteúdo |
|---|---|---|---|
| 1 | `LustLevel_Phase1_Cave.tscn` | 8736 × 5088 px | corredores de tiles, sem perigos e sem cães |
| 2 | `LustLevel_Phase2.tscn` | 7680 × 6240 px | corredores e poços de tiles, sem perigos e sem cães |
| 3 | `LustLevel_Phase3.tscn` | 7824 × 5808 px | 16 picos, 11 rochas que caem, uma armadilha de meia vida, 2 rampas, 4 plataformas móveis, sem cães |

- Nenhuma fase tem cães: o `demon.tscn` só é usado na `test_room.tscn`.
- As fases 1 e 2 são labirintos sem nada a evitar e a fase 3 é um percurso de armadilhas, o que
  corresponde a três jogos diferentes.
- Cada fase tem mais de quatro ecrãs de largura, e a fase 3 tem um salão maior do que o ecrã nos dois
  eixos. Os maciços de rocha com dezenas de tiles aparecem no ecrã como superfícies sem jogo.
- Mantém-se a progressão das três fases de baixo para cima.
- As cenas existentes ficam no projeto sem alterações, incluindo o `LustLevel_Phase1.tscn` antigo,
  que já não está no Play. O nível novo constrói-se em cenas novas (decisão E).

## 2. Decisões

| | Questão | Decisão |
|---|---|---|
| A | Quando é que um cão persegue o homem? | Só quando o vê e está dentro do ecrã. Desiste quando o perde de vista ou sai do ecrã, e regressa ao seu posto. |
| B | O nível 1 tem picos, rochas, rampas e plataformas móveis? | Não. Se regressam noutro nível decide-se mais tarde; os ficheiros mantêm-se no projeto. |
| C | Os cães descem desníveis? | Não: cada cão fica no chão onde começa. |
| D | Que tipo de labirinto? | Entrançado: caminhos que se separam e voltam a juntar, quase sem becos sem saída. |
| E | As cenas atuais são refeitas? | Não: as três fases novas são cenas novas, e as atuais ficam como estão, tal como os respetivos testes. |
| F | Como se constroem as salas? | Cada sala pode ser escrita em texto (ASCII) e convertida em cena por um gerador. Um teste do repositório lê as cenas das fases novas e verifica as regras das secções 5 e 8, qualquer que seja a forma como a cena foi construída. |

As seis decisões foram aprovadas pelo grupo a 26 de outubro de 2026. A decisão C é provisória: está
em estudo um salto curto dos cães, que, se for adotado, altera esta decisão e a regra da secção 3.

Em proposta, por aprovar pelo grupo:

| | Questão | Proposta |
|---|---|---|
| G | O nível é sempre o mesmo? | Não: cada partida gera um nível diferente. Os pontos fixos são o checkpoint entre fases (primeiro o mini-demónio, depois a conversa com o boss do nível) e a estrutura de cada fase; as salas entre eles são sorteadas a partir de um conjunto de salas feitas à mão, segundo as regras dessa fase. O mesmo molde aplica-se aos outros níveis, com regras próprias. Detalhe na secção 6, Geração por partida. |

Com a decisão G, o gerador da decisão F continua a ser a ferramenta que constrói cada sala a partir
de texto; a montagem do nível em cada partida é um sistema à parte.

## 3. A regra do nível

**O chão é dos cães, a altura é do homem, e cada fase retira-lhe mais chão.**

Um cão não sobe, não salta para cima e para à beira de um desnível. O homem salta 5 tiles e sobe
paredes e chaminés. O nível desenha-se, por isso, em dois andares: em baixo, os chãos onde os cães
vivem; em cima, poleiros, paredes e passagens a que só o homem chega.

```
   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  teto
            ┌──┐          ┌──┐       poleiros: só o homem chega (até 5 tiles)
  H         └──┘          └──┘
 ━━━━┓   c       c    ━━━━━━━━━┏━━━  chão dos cães: um degrau ou uma borda retém-nos
     ┗━━━━━━━━━━━━━━━━┛
```

A regra serve o tema. Na luxúria, os cães agarram o homem e fazem-no afundar; subir é resistir. Serve
também o final do jogo, em que a subida era o teste. Por ser a mesma regra nas três fases, cada vez
mais apertada, as fases leem-se como partes do mesmo nível:

| Fase | Etapa | A quem pertence o chão | O que o jogador aprende |
|---|---|---|---|
| 1 | apresentar e repetir | ao homem; os cães estão isolados | cada regra dos cães em separado, sem texto, primeiro sem risco e depois com algum |
| 2 | desenvolver e combinar | aos cães | a escolher o caminho em função dos cães, combinando as regras |
| 3 | reviravolta e conclusão | aos cães, quase todo | a altura deixa de bastar: para subir, tem de descer aos chãos dos cães com o crucifixo; termina com a corrida até à tenda |

Duas fontes propõem a mesma estrutura. Hayashida defende um conceito por nível, desenvolvido do
princípio ao fim em quatro etapas (apresentar, desenvolver, reviravolta, concluir), com a reviravolta
e o final planeados primeiro (Nutt, 2012). Dormans (2010) descreve a aprendizagem de uma técnica em
separado, a sua repetição, a combinação com outras e o teste final. Neste nível, o conceito é a regra
acima, a reviravolta é a altura deixar de chegar e o final é a corrida até à tenda.

As ofertas da Asmodeu surgem entre as fases. Por isso, o fim das fases 1 e 2 é o momento de maior
esforço de cada uma: uma oferta feita a um jogador descansado não constitui uma tentação.

## 4. Medidas

Grelha de 48 px. O ecrã tem 1920 × 1080 px, ou 40 × 22,5 tiles; em 21:9, até 2520 px, ou
52,5 tiles. Os valores vêm do README (secção Medidas para o desenho de níveis) e dos ficheiros de
afinação indicados, e são provisórios até serem afinados em jogo.

**Homem e cão**

| Medida | Valor | Tiles | Origem |
|---|---|---|---|
| dimensão do homem e do cão | 48 × 96 px | 1 × 2 | `player.tscn`, `demon.tscn` |
| corrida do homem | 720 px/s | | README |
| perseguição do cão | 560 px/s | | `demon_stats.gd`: em terreno plano, o homem consegue sempre fugir |

**Saltos do homem**

| Medida | Valor | Tiles | Origem |
|---|---|---|---|
| salto completo | 240 px | 5 | README |
| salto mínimo (botão largado logo) / com 0,1 s de botão | 88 / 153 px | 1,8 / 3,2 | README |
| vão sempre transponível / nunca transponível | até 431 / 579 px ou mais | até 8 / 13 ou mais | README |
| plataforma sempre alcançável / inalcançável com uma parede ao alcance | até 379 / 571 px ou mais | até 7 / 12 ou mais | README |
| distância de um salto da parede até à altura de partida | 444 px | 9 | README |
| chaminé sempre subida / nunca subida | até 174 / 528 px ou mais | até 3 / 11 ou mais | README; entre os dois valores, a subida depende da perícia e fica fora do caminho obrigatório |
| degrau que trava um cão | 48 px | 1 | `demon_attack.gd`: nenhum salto do cão passa dos 32 px |

**Cão** (valores de `lust_demon_stats.tres`, salvo indicação em contrário)

| Medida | Valor | Tiles |
|---|---|---|
| visão em frente / atrás | 1100 px / 20 % desse valor (220 px) | 23 / 4,6 |
| perde o homem a / desiste depois de o perder de vista | 1600 px / 0,5 s | 33 |
| só persegue dentro do ecrã; desiste a partir de | 160 px para lá da borda do ecrã | 3,3 |
| ronda: largura / velocidade | 480 px / 150 px/s | 10 |
| regresso ao posto | 200 px/s | |
| mordida: alcance / aviso | 100 px / 0,2 s | 2 |
| investida: alcance / distância do salto / aviso | 360 px / 200 a 420 px / 0,35 s (`demon_attack.gd`) | 7,5 / 4 a 9 |
| investida: condições | chão até ao ponto de aterragem e o homem a menos de 24 px de diferença de altura | 0,5 |

**Crucifixo** (`crucifix_stats.gd`)

| Medida | Valor | Tiles |
|---|---|---|
| raio | 200 px | 4 |
| uso | só no chão, com o homem a 25 % da velocidade (180 px/s) e sem saltar | |
| duração máxima / recarga | 5 s / 15 s | |

## 5. Peças de uma sala

Cada sala é composta pelas peças seguintes. Nenhuma é uma armadilha: todas resultam do que o cão não
consegue fazer e do que o homem consegue.

| Peça | Função | Medida |
|---|---|---|
| Degrau-refúgio | mostrar que o cão não sobe | 1 tile ou mais acima do chão do cão |
| Poleiro | esperar que o cão passe, se vire ou desista | 3 a 5 tiles acima do chão dos cães |
| Corredor do crucifixo | sem poleiros nem teto alto: só se atravessa pelo chão, com o crucifixo | teto a 4 tiles ou menos |
| Pista da investida | chão plano e comprido onde o cão salta: perigo | 10 tiles ou mais, sem vãos |
| Vão que corta | interrompe a perseguição e a investida | 3 a 8 tiles |
| Pilar que tapa a vista | passar sem ser visto | altura do homem (2 tiles) ou mais |
| Chaminé de fuga | saída vertical que só o homem usa | 3 tiles de largura ou menos |
| Descida obrigatória | o caminho de cima obriga a pousar num chão dos cães | chão de 9 tiles ou mais, para o raio do crucifixo |

Regras de construção de uma sala:

1. Uma ideia de cão por sala. A sala é também uma zona de câmara e o ponto de recomeço depois de o
   homem afundar.
2. Primeiro a missão, depois o espaço (Dormans, 2010). Descreve-se o que o jogador faz na sala, por
   ordem (ver o cão de cima, esperar no poleiro, descer, correr, erguer o crucifixo), e só depois se
   desenha a geometria que o exige. Smith et al. (2009) seguem o mesmo princípio com o ritmo, ações
   primeiro e geometria depois, e mostram que plataformas colocadas ao acaso são jogáveis mas não têm
   fluxo, que é a crítica dos docentes.
3. Entra-se por cima. A entrada de cada sala mostra de cima o chão dos cães, para que o jogador veja
   os cães e o caminho antes de se comprometer (a vista à entrada, *The Level Design Book*).
4. Entre duas salas há um descanso: um troço curto, sem cães, com a porta da sala seguinte (os
   intervalos entre grupos de ritmo de Smith et al., 2009).
5. O caminho segue uma linha clara, sempre a subir, sem serpentear: os níveis feitos à mão seguem
   caminhos regulares (Smith et al., 2009). É o oposto dos corredores atuais da fase 1.
6. Os chãos dos cães são planos e contínuos. Um degrau de um tile trava um cão; num chão irregular,
   os cães ficariam retidos a cada passo e pareceriam avariados. Só há degraus onde se pretende travar
   um cão.
7. Onde a sala exige o crucifixo, há chão plano e livre à volta.
8. A saída está à vista, ou é indicada pela forma e pela luz.
9. Sem picos, rochas, rampas nem plataformas móveis (decisão B). A variedade vem das situações (posto,
   ronda, matilha, altura, linha de vista) e não de tipos de inimigo: um encontro com um só tipo de
   inimigo funciona como tutorial ou descanso (*The Level Design Book*), pelo que cada sala tem de
   mudar a situação.

## 6. As três fases

### Fase 1: apresentar

Uma sala por regra, sempre com uma saída segura, até à prova final. As salas 1.2 a 1.5 têm duas
metades: a primeira mostra a regra sem risco, a segunda exige-a com algum risco. Repete-se antes de
combinar (Dormans, 2010).

| Sala | O que acontece | O que ensina |
|---|---|---|
| 1.1 Acordar | o homem acorda; andar e saltar estão desenhados no cenário; o demónio do tutorial fala | os controlos, sem cães |
| 1.2 O cão que não sobe | o homem passa num degrau acima de um chão com um cão; o cão vê-o, corre, para no degrau e anda de um lado para o outro a ladrar | os cães veem, perseguem e não sobem |
| 1.3 Atravessar | um cão de ronda num chão, um poleiro por cima e a saída do outro lado | a ronda, a visão e o tempo |
| 1.4 O crucifixo | corredor baixo, sem poleiros; um cão vem de frente; o crucifixo está desenhado na parede | erguer o crucifixo, o cão é repelido, seguir em frente |
| 1.5 A investida | chão comprido onde um cão salta; depois, chão cortado por vãos | a investida, e que um vão a interrompe |
| 1.6 Dois | dois cães no mesmo chão, com poleiros | a matilha |
| 1.7 Prova | as salas 1.3 a 1.6 combinadas e sem saída segura; termina na porta onde a Asmodeu faz a oferta | o pico da fase |

Um caminho alto opcional, com um salto da parede difícil, evita a sala 1.6: a primeira escolha do
jogador.

### Fase 2: desenvolver

Três troços. Em cada um, dois ou três caminhos separam-se e voltam a juntar-se:

```
          ┌── alto: paredes e poleiros, sem cães, saltos difíceis ──┐
 entrada ─┼── baixo: chão dos cães, fácil de andar, com o crucifixo ─┼─ junção ─ troço seguinte
          └── escondido: atrás de pilares, fora da vista dos cães ───┘
```

- Os caminhos distinguem-se pelos cães e não pelos saltos. Nenhum é sempre o melhor.
- Sem becos sem saída: o nível 1 não tem nada a descobrir, pelo que um beco só faz perder tempo.
- Um labirinto sem becos pode ser mais difícil do que um com uma única solução, porque o jogador anda
  em círculos (Pullen). Por isso, cada troço é curto, cada junção é diferente das outras e todos os
  caminhos sobem: quem anda em círculos percebe que não subiu.
- Cada caminho mostra o risco que tem antes de o jogador entrar nele, e quem quer mais risco
  escolhe-o: o jogador controla a dificuldade (Taylor, 2013).
- Depois do checkpoint intermédio, uma porta que só abre do outro lado cria um atalho de regresso.
- Em cada junção, uma abertura na rocha mostra a tenda da Asmodeu, que serve de ponto de referência.
- Do caminho alto, o jogador vê os cães em baixo a reagir à sua presença (secção 7): a ameaça é
  visível mesmo quando não o alcança.
- O último troço junta os três caminhos num só chão com uma matilha: o estreitamento antes da segunda
  oferta.

### Fase 3: combinar

Uma subida num poço fechado. Começa como as outras fases, com o homem nas paredes e os cães em baixo.
A reviravolta: a meio, as paredes deixam de chegar umas às outras, e a única forma de subir é descer
a um chão dos cães, atravessá-lo com o crucifixo e subir do outro lado. A regra que o jogador
aprendeu, "a altura é minha", deixa de bastar, e ele tem de entrar onde a luxúria vive. Não há
mecânicas novas: a reviravolta vem do espaço. Os cães em baixo seguem-no com o olhar e andam de um
lado para o outro. O final é um chão comprido até à tenda, com a matilha a aproximar-se por trás: a
última pista da investida.

### O que liga as fases

- A progressão é sempre ascendente.
- A saída de uma fase é a entrada da seguinte, com a mesma peça de porta.
- A tenda da Asmodeu vê-se ao longe na fase 1, mais perto na fase 2, e é onde a fase 3 termina.
- Os mesmos tiles e a mesma marca no chão dos cães nas três fases, distinguíveis pela forma e não só
  pela cor.

### Geração por partida (proposta, decisão G)

O princípio vem de Dormans (2010): a missão e o espaço são duas estruturas, e um nível gerado sem
estrutura de missão tem "a random feel", que é a crítica dos docentes ao nível atual. Por isso, a
missão de cada fase (o que o jogador aprende e por que ordem) é fixa, e só o espaço que a cumpre
varia de partida para partida. As tabelas acima descrevem a missão: cada sala delas passa a ser um
lugar, com duas ou três variantes feitas à mão que ensinam o mesmo.

| Parte | Fixo | Gerado |
|---|---|---|
| Fase 1 | a ordem das lições (1.1 a 1.7) | a variante de cada lugar |
| Checkpoint entre fases | o mini-demónio, a conversa com o boss e a oferta | nada |
| Fase 2 | três troços, os seus caminhos e ciclos, e as junções, incluindo a final com a matilha; o checkpoint intermédio e a porta-atalho | a variante de cada caminho de cada troço |
| Fase 3 | o poço, a reviravolta a meio e a corrida final até à tenda | os troços entre esses pontos |

Regras da geração:

1. Cada partida tem uma seed, registada e visível (por exemplo, no menu de pausa), para repetir um
   erro ou partilhar um nível. Recomeçar uma sala depois de afundar mantém a sala; um jogo novo
   sorteia uma seed nova.
2. Todas as salas de um lugar têm a mesma entrada e a mesma saída (posição e altura da porta), para
   encaixarem com qualquer variante do lugar vizinho.
3. Cada variante passa sozinha na lista da secção 11. O teste das regras gera muitas seeds e verifica
   que cada nível montado se completa, que a curva de intensidade de cada caminho acaba no pico antes
   da oferta (secção 10, ponto 5) e que o número de cães por sala respeita o orçamento.
4. As variantes de um lugar mudam a situação (posto, ronda, altura, linha de vista), e não só a
   decoração: duas variantes que se jogam da mesma maneira contam como uma.

O nível fixo é o primeiro passo da geração e não um desvio: uma variante por lugar é o nível sem
sorteio. Se o tempo não chegar, a Alpha leva uma variante por lugar e o sorteio entra depois.

#### Método de montagem

A montagem faz-se sobre um molde fixo, com base na pesquisa da secção 10, pontos 6 a 9. Ficaram de
lado duas alternativas: sortear um de vários moldes por troço, que multiplicava as variantes a
construir, e colocar as salas livremente a partir de um grafo (Ma et al., 2014), que em plataformas
tem dificuldade com ciclos (ponto 8) e não respeita a subida contínua nem as zonas de câmara.

1. O grafo da fase 2 desenha-se à mão uma vez: os três troços, os caminhos de cada um, as junções,
   os ciclos, o checkpoint intermédio e a porta-atalho. Cada caminho de cada troço é um lugar, com um
   retângulo (a zona de câmara) e portas de entrada e de saída em posição e altura fixas. As junções
   são salas fixas, iguais em todas as partidas: guardam os marcos (a abertura para a tenda), o
   checkpoint e a porta-atalho.
2. Cada variante pertence a um lugar, ocupa o retângulo desse lugar e usa as portas dele (itens 31 e
   33). O molde e as listas de variantes guardam-se num ficheiro de dados (`Resource`), que se altera
   sem mexer no código.
3. A montagem corre uma vez, ao carregar a fase, e nunca durante o jogo. Usa uma instância própria de
   `RandomNumberGenerator`, que nenhum outro sistema partilha. Cada lugar recebe uma semente derivada
   da seed da partida e do identificador do lugar, por uma fórmula fixa no código, para que
   acrescentar uma variante a um lugar não altere o sorteio dos outros. Em cada lugar, todas as
   variantes têm a mesma probabilidade.
4. A intensidade de uma variante mede-se pelo que o caminho tem: nos caminhos baixo e escondido, o
   número de cães ativos e a menor distância a um cão pelo chão (secção 10, pontos 1 e 2); no caminho
   alto, o número de saltos de perícia, isto é, vãos e chaminés entre os valores "sempre" e "nunca" da
   secção 4. Cada troço tem uma faixa para cada medida, e as faixas sobem de troço para troço até ao
   pico na junção final (ponto 5). Todas as variantes de um lugar ficam dentro da faixa do seu troço
   (item 34). Como a verificação incide sobre as listas de variantes, a curva vale para qualquer seed.
5. Pela mesma razão, nenhuma seed produz um nível mais fácil, e começar um jogo novo à procura de um
   nível fácil não compensa. Como os caminhos baixo e escondido partilham a faixa do troço, qual deles
   é mais seguro pode mudar de partida para partida.
6. O sorteio é código puro: recebe a seed e o molde e devolve a lista das variantes escolhidas, sem
   carregar cenas. O teste corre 10 000 seeds (Smith e Whitehead, 2010) e verifica que a mesma seed dá
   sempre o mesmo nível, que cada lugar recebe uma variante sua, que todas as variantes aparecem com
   frequência próxima da uniforme, e os itens "teste" que dependem de mais de uma sala, como o 29.
   Cada variante instancia-se uma vez para verificar os itens 31, 33, 34 e 35 contra o molde. Com as
   portas fixas e cada variante completável da entrada à saída, o nível montado completa-se (ponto 6).
   O tempo de montar e instanciar a fase mede-se e regista-se no README.
7. Na Alpha, com uma variante por lugar, o mesmo sistema monta o nível fixo. O método serve também as
   fases 1 e 3: na fase 1, os lugares são as salas 1.1 a 1.7, em linha; na fase 3, os troços entre o
   poço, a reviravolta e a corrida final.

## 7. Os cães

Antes desta revisão, um cão sem o homem à vista ficava parado; via-o por um único raio, que a própria
plataforma do homem tapava; passava de parado a perseguir no mesmo instante; esquecia-o ao perdê-lo
de vista; via tão bem para trás como para a frente; e, sem lhe conseguir chegar, parava hirto à beira
do desnível. Um inimigo assim não é plausível nem permite desenhar salas à sua volta. O comportamento
abaixo está implementado e testado no ramo do nível novo; os valores são os da secção 4.

| Estado | Comportamento |
|---|---|
| Ronda | anda num troço do seu chão, à volta do posto, com pausas sorteadas por cão, para que dois cães não se movam em sincronia; fora do ecrã, para |
| Alerta | ao ver o homem, para 0,3 s virado para ele, com um sinal de exclamação e um som; depois persegue |
| Perseguição | segue o homem pelo seu chão; com dois ou mais cães, cada um mantém distância ao da frente, se esse também perseguir o homem |
| Procura | se uma parede tapa o homem, vai a 300 px/s ao último ponto onde o viu e fareja durante 2,5 s, virando-se a meio, com um sinal de interrogação; se o voltar a ver, alerta; se não, regressa |
| Fora de alcance | se o homem está acima ou abaixo do alcance dos ataques, para virado para ele e ladra; depois anda de um lado para o outro num troço de 160 px e ladra em cada extremo; contra uma parede ou uma borda do lado do homem, salta no sítio; ao fim de 3 s deixa-o, até ele voltar ao alcance |
| Regresso | desiste quando perde o homem de vista e a procura não o encontra, quando o homem fica a mais de 1600 px ou quando o cão passa 160 px para lá da borda do ecrã; volta ao posto a passo e retoma a ronda |

A visão usa dois pontos do corpo do homem (cabeça e meio), basta um estar à vista, e alcança muito
mais para a frente do que para trás, para que o caminho escondido da fase 2 possa passar nas costas
de um cão. Quando o homem afunda e a sala recomeça, cada cão volta ao posto. Um cão só começa a
perseguir dentro do ecrã, pelo que nenhum ataca sem o jogador o ver (secção 8).

Fundamentação:

- No vocabulário de Bright (2014), o cão é um perseguidor preso ao chão, a que a ronda junta o
  comportamento de quem anda de um lado para o outro. Os inimigos bem desenhados combinam vários
  atributos e passam de um para outro por gatilhos; aqui, os gatilhos são ver o homem, perdê-lo de
  vista, deixar de lhe chegar e sair do ecrã.
- Num sistema de deteção de guardas descrito por Thompson (2020), o inimigo não descobre o jogador de
  repente: a deteção acumula com o tempo, e os raios partem para vários pontos do corpo. Daí o alerta
  e os dois pontos da visão.
- O mesmo texto defende que o inimigo deve ser sempre plausível, mais do que inteligente, e que o
  jogador tem de perceber a sua intenção pela imagem e pelo som. Daí os sinais do alerta e da procura
  e o cão fora de alcance que nunca fica imóvel.
- Diferença assumida: nesse sistema, um guarda alertado não volta ao estado normal; aqui, o cão
  regressa ao posto, porque a sala tem de se poder repor e porque os docentes pediram que os cães
  desistam.

Por fazer:

- o cão a dormir, que só acorda com o homem muito perto ou à vista de frente (variante de sala,
  prioridade baixa);
- virar-se com demora, adiado para depois do primeiro playtest;
- a arte e o som: andar, correr, farejar, sentar, olhar à volta, alerta, ladrar de frustração e
  arranhar a parede; ladrido com variação de tom por cão. Por agora, o cão é um retângulo provisório,
  e o alerta e a procura usam sinais e sons provisórios;
- mostrar para onde o cão está virado e que está a regressar ao posto: com o retângulo simétrico, não
  se distingue.

## 8. Câmara e grutas

A câmara mostra sempre os dois limites do eixo em que o homem não se desloca: num corredor, o chão e
o teto; num poço, as duas paredes.

| Regra | Valor (zoom 1) |
|---|---|
| altura livre de um corredor | até cerca de 16 tiles (o ecrã tem 22,5) |
| largura de um poço | até cerca de 30 tiles (o ecrã tem 40) |
| espessura da rocha entre passagens | 2 a 6 tiles, para que o ecrã seja quase todo jogo |
| rocha à volta do nível | meio ecrã: 20 tiles na horizontal (26 em 21:9) e 12 na vertical; em alternativa, zonas de câmara que nunca ultrapassam o limite |
| salas maiores do que o ecrã nos dois eixos | não existem; uma sala grande tem câmara fixa |

Numa zona com zoom superior a 1, os limites de altura e largura reduzem-se na mesma proporção. Cada
sala tem uma zona de câmara, construída com as regras de zonas, zoom e miradouros da secção Câmara do
README. Keren (2015) descreve câmaras com regras diferentes por região do mesmo nível e defende que a
câmara mostra sempre o que importa. Um cão que persegue o homem está no ecrã, pelo que a desistência
fora do ecrã (decisão A) é também uma questão de justiça: nenhum cão ataca sem o jogador o ver.

## 9. Playtests

| Hipótese | O que observar | Critério de sucesso |
|---|---|---|
| Na sala 1.2, o jogador percebe sem texto que o cão não sobe | se fica no degrau a observar o cão ou se foge | 4 em 5 jogadores ficam sem hesitar |
| Na sala 1.4, o jogador usa o crucifixo sem outra ajuda além do desenho na parede | quantas vezes é mordido antes de o usar | 4 em 5 usam-no à primeira ou à segunda tentativa |
| Na fase 2, os caminhos são escolhas e nenhum é óbvio | que caminho cada jogador escolhe em cada troço | nenhum caminho recebe mais de 70 % das escolhas |
| Os cães parecem vivos | o que o jogador diz dos cães quando não o perseguem | nenhum jogador diz que estão "parados" ou "avariados" |
| O fim das fases 1 e 2 cansa o suficiente para que a oferta seja uma tentação | quantos jogadores hesitam ou aceitam a oferta | pelo menos 1 em 5 hesita |

## 10. Contributos da investigação e questões em aberto

### O que a investigação acrescenta

1. **O risco de um caminho mede-se pela distância aos cães, ao longo do caminho.** O risco que os
   jogadores atribuem a um caminho furtivo corresponde sobretudo à distância ao inimigo medida
   contornando obstáculos (Tremblay et al., 2014, estudo pequeno), e a proximidade aos inimigos ao
   longo do percurso prevê a dificuldade e o prazer avaliados (Biemer e Cooper, 2024, 143 jogadores).
   Neste nível, a distância mede-se pelo caminho do cão: um poleiro a 3 tiles de um cão que não sobe é
   seguro. Na fase 2, o risco de cada caminho é a menor distância, pelo chão, a que passa de um cão, e
   o teste das regras pode calculá-la. Ressalva: o primeiro estudo usa um jogo furtivo visto de cima e
   o segundo um roguelike.
2. **A dificuldade sobe primeiro com o número de cães.** O número de inimigos é a métrica com mais peso
   na dificuldade e no prazer avaliados pelos jogadores, e a dispersão vertical dos inimigos acompanha
   o prazer, com ρ = 0,32 (Summerville et al., 2017, em níveis de um jogo de plataformas clássico). A
   curva de cada fase controla-se, por isso, pelo número de cães por sala e pela situação, e não por
   saltos mais difíceis. Os dois andares da regra do nível já distribuem os cães na vertical.
3. **O tipo de labirinto escolhe-se pelo efeito pretendido.** Uma fuga pede poucas junções e retas
   longas; uma busca que desoriente pede muitas junções (Kim et al., 2019). Confirma o final da fase 3,
   um chão comprido até à tenda, e os troços curtos da fase 2, que não pretendem desorientar. Das
   propriedades do artigo, adotam-se o enviesamento vertical (sobe-se sempre) e um fator oculto baixo
   (vê-se para onde se vai). Um beco que aponta para a saída engana o jogador; se algum beco ficar, não
   pode ser desse tipo.
4. **Ciclos em vez de ramos.** Dois arcos alternativos, com obstáculos diferentes, entre a entrada e o
   objetivo, e portas de sentido único que evitam o regresso pelo mesmo caminho (Boris the Brave, 2021,
   sobre o gerador cíclico de Dormans). Confirma os troços da fase 2 e a porta-atalho.
5. **Uma curva de intensidade por caminho.** Num nível não linear, a intensidade desenha-se ao longo
   de cada caminho do grafo, e não numa curva única (Geheeb et al., 2024; avaliação limitada a duas
   entrevistas). Na fase 2 há uma curva por caminho, e todas terminam no pico antes da oferta.
6. **Salas que se completam sozinhas não garantem um nível que se completa.** Num jogo de plataformas
   vertical, juntar segmentos completáveis um a seguir ao outro deu níveis completáveis em 11% dos
   casos (Biemer e Cooper, 2022; segmentos gerados, e não feitos à mão). Os geradores com salas-modelo
   evitam o problema com aberturas garantidas: cada tipo de sala tem as saídas que o caminho principal
   exige, e só ficam lado a lado salas com aberturas compatíveis (Shaker et al., 2016; Kazemi).
   Confirma a regra 2 da geração por partida (a mesma entrada e a mesma saída em todas as variantes de
   um lugar) e que o teste verifique o nível montado, e não só cada sala.
7. **Estrutura fixa e salas feitas à mão.** A montagem de salas feitas à mão sobre um grafo definido
   pelo designer aparece na investigação (Ma et al., 2014; Karavolos et al., 2015) e na prática: um
   mapa fixo, um grafo por zona com a entrada, a saída e as salas especiais colocadas primeiro, e salas
   sorteadas de um conjunto até uma cumprir as restrições do nó (Bénard, 2017). Karavolos et al. (2015)
   concluem que a noção de sala ajuda também em jogos de plataformas, e avisam que uma mudança no salto
   obriga a rever à mão todos os modelos.
8. **Os ciclos são a parte mais difícil de gerar.** Em plataformas, as salas têm poucas posições de
   porta e não há corredores para as ligar. Um gerador que coloca as salas livremente a partir de um
   grafo, derivado de Ma et al. (2014), demorava dezenas de segundos com grafos com ciclos e passou a
   aceitar só grafos acíclicos (Nepožitek, 2019). Smith et al. (2018) também geram só grafos acíclicos
   e deixam os ciclos e os atalhos para trabalho futuro.
9. **Um gerador avalia-se em muitos níveis.** Gerar 10 000 níveis, medir cada um e ver as medidas em
   histogramas mostra enviesamentos e lacunas que nenhum nível isolado revela (Smith e Whitehead, 2010).
   Um gerador feito de módulos precisa de testes a cada módulo, porque um erro no nível pode ter origem
   em qualquer passo (Karavolos et al., 2015). Para repetir um nível basta a seed: no Godot, cada
   instância de `RandomNumberGenerator` tem semente e estado próprios, e a mesma semente produz a mesma
   sequência (documentação do Godot).

### Questões em aberto

- **Identidade do nível.** As três fases têm de parecer do mesmo nível e do mesmo jogo à primeira
  vista, e não só pela lógica do espaço. Falta definir a linguagem visual e sonora da luxúria (paleta,
  luz, adereços recorrentes, fundo, ambiente sonoro), a sua evolução da fase 1 para a 3 à medida que a
  tenda se aproxima, e o que se mantém nos restantes níveis. O apoio teórico são as zonas de Lynch,
  que partilham características, e a repetição e os marcos (*The Level Design Book*, página
  Wayfinding), com base empírica fraca: é uma decisão de arte e de som.
- **Crucifixo e atalho.** O crucifixo está sempre disponível no nível 1: entre as fases, a oferta é o
  atalho, e o crucifixo só se perde com o encanto do final. As salas podem contar com ele. Falta
  definir que parte do nível o atalho evita.
- **"Baixo + salto".** Faz parte do vocabulário do homem, mas não tem medida no README. Medir antes de
  uma sala depender dele.
- **Salto dos cães.** Em estudo (secção 2, decisão C). Se for adotado, revêm-se a regra do nível, o
  degrau que trava um cão (secção 4) e o degrau-refúgio (secção 5).

### Orçamento por sala

Com 50 cães a perseguir ao mesmo tempo, os scripts custam 0,95 a 1,03 ms por passo e o pior passo
chega a 1,92 ms, dentro dos 2 ms que o projeto aceita por sistema. O limite de cães por sala é, por
isso, de legibilidade e não de custo: até 8 cães ativos no ecrã ao mesmo tempo, valor provisório a
confirmar no playtest. Uma sala que precise de mais mede-se de novo antes de ser aceite.

## 11. Lista de verificação por sala

Cada sala nova, ou alteração a uma sala, verifica-se contra esta lista antes de entrar no ramo do
nível. Cada item responde-se com sim ou não. Na coluna Verificação, "teste" indica que o teste das
regras o pode confirmar a partir da cena, e "à mão" que exige leitura do desenho ou do jogo.

| # | Item | Valor | Verificação |
|---|---|---|---|
| | **Estrutura** | | |
| 1 | A missão da sala (o que o jogador faz, por ordem) está escrita antes da geometria | | à mão |
| 2 | A sala tem uma única ideia de cão, identificada (posto, ronda, matilha, altura, linha de vista, investida ou crucifixo) | | à mão |
| 3 | A saída fica acima da entrada | | teste |
| 4 | Da entrada vê-se o chão dos cães de cima | chão dos cães dentro do ecrã no ponto de entrada | teste |
| 5 | No ponto de entrada, o homem está fora do alcance dos ataques dos cães | mais de 24 px acima do chão de cada cão, ou fora da sua visão | teste |
| 6 | Há um descanso sem cães entre a sala e a porta seguinte | | teste |
| 7 | A saída está à vista ou é indicada pela forma e pela luz | | à mão |
| 8 | Não há becos sem saída; se houver, nenhum aponta para a saída | | à mão |
| | **Chão dos cães** | | |
| 9 | Cada cão está num chão plano e contínuo, sem degraus nem vãos no seu troço de ronda | troço de 480 px (10 tiles) à volta do posto | teste |
| 10 | Os troços de ronda de dois cães no mesmo chão não se sobrepõem | | teste |
| 11 | Os degraus de 1 tile num chão de cães estão só onde se pretende travar um cão | | à mão |
| 12 | Não há picos, rochas, rampas nem plataformas móveis | | teste |
| 13 | Uma pista da investida tem chão plano e sem vãos | 10 tiles ou mais | teste |
| | **Alcance do homem** | | |
| 14 | Os vãos do caminho obrigatório são sempre transponíveis; os que devem travar o homem são intransponíveis | até 431 px (8 tiles); 579 px (13 tiles) ou mais | teste |
| 15 | As chaminés do caminho obrigatório sobem-se sempre | até 174 px (3 tiles) de largura | teste |
| 16 | As plataformas do caminho obrigatório alcançam-se com margem | até 192 px (4 tiles) sem parede; até 379 px com uma parede ao alcance | teste |
| 17 | Vãos entre 431 e 579 px e chaminés entre 174 e 528 px existem só em caminhos opcionais | | à mão |
| | **Crucifixo** | | |
| 18 | Onde a sala exige o crucifixo, há chão plano e livre à volta | 9 tiles ou mais | teste |
| 19 | Um corredor do crucifixo atravessa-se dentro da duração do crucifixo, com margem | até 15 tiles (4 s a 180 px/s; a duração é 5 s) | teste |
| 20 | Dois usos obrigatórios do crucifixo estão separados pela recarga, ou há entre eles um sítio seguro onde esperar | 15 s | à mão |
| | **Câmara** | | |
| 21 | A sala tem uma zona de câmara e o ponto de recomeço está dentro dela | | teste |
| 22 | Altura livre de um corredor e largura de um poço, com zoom 1 (reduzidas na proporção do zoom da zona) | até 16 e 30 tiles | teste |
| 23 | Espessura da rocha entre passagens | 2 a 6 tiles | teste |
| 24 | A sala não é maior do que o ecrã nos dois eixos, ou tem câmara fixa | 40 × 22,5 tiles | teste |
| 25 | A sala funciona em 21:9 sem mostrar o exterior do nível | 2520 px de largura | teste |
| | **Cães, ritmo e risco** | | |
| 26 | Cães ativos no ecrã ao mesmo tempo | até 8 | teste |
| 27 | Nenhum cão começa a perseguir fora do ecrã | `chases_only_on_screen` ligado | teste |
| 28 | Na fase 2, cada caminho mostra o seu risco antes de o jogador entrar nele | | à mão |
| 29 | Na fase 2, os caminhos de um troço têm riscos diferentes | menor distância a um cão, pelo chão, diferente entre caminhos | teste |
| 30 | A informação do chão dos cães não depende só da cor | marca distinguível pela forma | à mão |
| | **Geração (decisão G)** | | |
| 31 | A entrada e a saída seguem as portas do lugar, e a sala encaixa com qualquer variante dos lugares vizinhos | posição e altura da porta iguais em todas as variantes do lugar | teste |
| 32 | A variante muda a situação face às outras do mesmo lugar | | à mão |
| 33 | A sala ocupa o retângulo do lugar | igual em todas as variantes do lugar | teste |
| 34 | A intensidade da variante está dentro da faixa do troço | cães ativos e menor distância a um cão pelo chão (baixo e escondido); saltos de perícia (alto) | teste |
| 35 | Da entrada chega-se à saída pelo caminho obrigatório | com os saltos sempre possíveis da secção 4 | teste |

## 12. Ordem do trabalho

1. Aprovação do documento e das decisões da secção 2 pelo grupo: feita a 26 de outubro de 2026.
2. Comportamento dos cães (secção 7): feito.
3. Em papel: o grafo de salas de cada fase e as curvas de intensidade, uma por caminho na fase 2.
4. O gerador de salas a partir de texto e o teste das regras, que verifica os itens "teste" da
   secção 11.
5. Greybox da fase 1 com cães, numa cena nova, e playtest com as hipóteses da secção 9.
6. Greybox das fases 2 e 3, em cenas novas, com o que a fase 1 ensinou.
7. As fases novas entram na lista Levels do menu principal ao lado do blockout atual, que se mantém
   no Play até o grupo decidir retirá-lo. As cenas atuais e os respetivos testes não mudam.
8. Com a decisão G aprovada: o método de montagem (pesquisa feita, secção 10, pontos 6 a 9); variantes de cada
   lugar; o sistema que monta o nível a partir da seed; o teste que verifica muitas seeds.

O nível constrói-se no ramo `feat/pj2d-level1`, criado a partir do `pj2d-lust-redesign`, que tem os
cães. Cada sala entra por pull request para o `pj2d-lust-redesign`, revisto com a lista da secção 11;
no fim, o `pj2d-lust-redesign` entra no `dev`.

Questão para os docentes: o "Mapa" dos critérios da alpha é um mapa dentro do jogo? Num labirinto,
isso altera a fase 2.

## Referências

Os artigos lidos estão em PDF em `docs/referencias/`, com um índice que liga cada um às secções que
o usam; os textos da web foram lidos no próprio site. Para cada fonte indica-se a versão lida e o que dela se usa.

Artigos lidos:

- Biemer, C. F. e Cooper, S. (2022). *On Linking Level Segments*. IEEE CoG 2022, pp. 199–205.
  DOI 10.1109/CoG51982.2022.9893705. Preprint arXiv 2203.05057v2. Usado: segmentos completáveis
  juntos por concatenação nem sempre formam um nível completável (11% num jogo de plataformas
  vertical).
- Biemer, C. e Cooper, S. (2024). *Solution Path Heuristics for Predicting Difficulty and Enjoyment
  Ratings of Roguelike Level Segments*. FDG 2024. DOI 10.1145/3649921.3659846. Versão publicada.
  Usado: proximidade aos inimigos ao longo do caminho como preditor da dificuldade e do prazer.
- Dormans, J. (2010). *Adventures in Level Design: Generating Missions and Spaces for Action
  Adventure Games*. PCG Workshop 2010. DOI 10.1145/1814256.1814257. Versão publicada,
  https://www.pcgworkshop.com/archive/dormans2010adventures.pdf. Usado: missão e espaço como duas
  estruturas, a missão primeiro; aprender, repetir, combinar e testar; ciclos no espaço sem encurtar a
  missão; níveis gerados sem estas estruturas com "a random feel".
- Geheeb, J., Dyrda, D. e Geheeb, S. (2024). *PaceMaker: A Practical Tool for Pacing Video Games*.
  IEEE CoG 2024 (segundo o DBLP). Preprint arXiv 2408.15001v2. Usado: uma curva de intensidade por
  caminho num nível não linear.
- Karavolos, D., Bouwer, A. e Bidarra, R. (2015). *Mixed-Initiative Design of Game Levels: Integrating
  Mission and Space into Level Generation*. FDG 2015. Versão publicada,
  http://www.fdg2015.org/papers/fdg2015_paper_25.pdf (sem DOI). Usado: salas-modelo também em jogos de
  plataformas; uma mudança no salto obriga a rever os modelos; testes a cada módulo do gerador.
- Kim, P. H., Grove, J., Wurster, S. e Crawfis, R. (2019). *Design-Centric Maze Generation*. FDG 2019
  (PCG Workshop). DOI 10.1145/3337722.3341854. Versão publicada. Usado: junções e retas segundo o
  efeito; enviesamento vertical, fator oculto e becos que apontam para a saída.
- Ma, C., Vining, N., Lefebvre, S. e Sheffer, A. (2014). *Game Level Layout from Design
  Specification*. Computer Graphics Forum 33(2), pp. 95–104 (Eurographics 2014). DOI 10.1111/cgf.12314.
  Preprint do autor, http://chongyangma.com/publications/gl/2014_gl_preprint.pdf. Usado: montagem de
  salas feitas à mão a partir de um grafo de ligações definido pelo designer, com uma porta em cada
  ligação.
- Shaker, N., Liapis, A., Togelius, J., Lopes, R. e Bidarra, R. (2016). *Constructive generation
  methods for dungeons and levels*. Em N. Shaker, J. Togelius e M. J. Nelson, *Procedural Content
  Generation in Games*, Springer, cap. 3, pp. 31–55. DOI 10.1007/978-3-319-42716-4_3. Cópia dos
  autores, https://www.pcgbook.com/chapter03.pdf. Usado: salas-modelo com aberturas garantidas ao longo
  de um caminho principal.
- Smith, G., Treanor, M., Whitehead, J. e Mateas, M. (2009). *Rhythm-Based Level Generation for 2D
  Platformers*. FDG 2009, pp. 175–182. Versão publicada,
  https://www.cas.mcmaster.ca/~carette/CAS761/rhythm-based-level-generation-platformers.pdf. Usado:
  grupos de ritmo com descanso entre eles; ações primeiro, geometria depois; plataformas ao acaso
  jogáveis mas sem fluxo; caminhos regulares.
- Smith, G. e Whitehead, J. (2010). *Analyzing the Expressive Range of a Level Generator*. PCG
  Workshop 2010. DOI 10.1145/1814256.1814260. Versão publicada,
  https://www.pcgworkshop.com/archive/smith2010analyzing.pdf. Usado: avaliar um gerador em muitos
  níveis (10 000), com as medidas em histogramas.
- Smith, T., Padget, J. e Vidler, A. (2018). *Graph-based Generation of Action-Adventure Dungeon Levels
  using Answer Set Programming*. FDG 2018. DOI 10.1145/3235765.3235817. Versão publicada,
  https://www.pcgworkshop.com/archive/smith2018graphbased.pdf. Usado: geração só de grafos acíclicos,
  com os ciclos e os atalhos deixados para trabalho futuro.
- Summerville, A., Mariño, J. R. H., Snodgrass, S., Ontañón, S. e Lelis, L. H. S. (2017).
  *Understanding Mario: An Evaluation of Design Metrics for Platformers*. FDG 2017.
  DOI 10.1145/3102071.3102080. Versão publicada. Usado: o número de inimigos como métrica de maior
  peso; a dispersão vertical dos inimigos e o prazer.
- Tremblay, J., Andrade Torres, P. e Verbrugge, C. (2014). *Measuring Risk in Stealth Games*. FDG
  2014. Cópia do autor, https://www.cs.mcgill.ca/~jtremb59/Papers/fdg2014_paper_33.pdf (DOI não
  encontrado). Usado: o risco percebido e a distância ao inimigo medida pelo caminho.

Textos de prática (não revistos por pares):

- Bénard, S. (2017, 29 mar.). *Building the Level Design of a procedurally generated Metroidvania: a
  hybrid approach.* Game Developer.
  https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach-.
  Usado: mapa fixo, grafo por zona e salas feitas à mão sorteadas até cumprirem as restrições de cada
  nó.
- Boris the Brave (2021, 10 abr.). *Dungeon Generation in Unexplored*.
  https://www.boristhebrave.com/2021/04/10/dungeon-generation-in-unexplored/. Sobre o gerador cíclico
  de Dormans; a fonte primária é um capítulo de livro, não lido. Usado: ciclos com dois arcos e portas
  de sentido único.
- Bright, G. (2014, 22 abr.). *Build a Bad Guy Workshop: Designing enemies for retro games*. Game
  Developer. https://www.gamedeveloper.com/design/build-a-bad-guy-workshop-designing-enemies-for-retro-games.
  Usado: atributos dos inimigos (Pacer, Follower, preso ao terreno) e gatilhos.
- Godot Engine. *Random number generation*. Documentação do Godot, versão stable.
  https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html. Usado: cada
  `RandomNumberGenerator` tem semente e estado próprios; a mesma semente produz a mesma sequência.
- Kazemi, D. *Spelunky Generator Lessons*, partes 1 e 2. https://tinysubversions.com/spelunkyGen/ e
  https://tinysubversions.com/spelunkyGen2/. Usado: caminho principal numa grelha, com tipos de sala
  que garantem as saídas; 8 a 16 modelos por tipo de sala.
- Keren, I. (2015). *Scroll Back: The Theory and Practice of Cameras in Side-Scrollers*. Game
  Developer, a partir da palestra no GDC 2015.
  https://www.gamedeveloper.com/design/scroll-back-the-theory-and-practice-of-cameras-in-side-scrollers.
  Usado: mostrar sempre o que importa; regras de câmara por região.
- Nepožitek, O. (2019, 13 mar.). *Platformers* (série sobre o gerador de masmorras baseado em grafos).
  https://ondra.nepozitek.cz/blog/graph-based-dungeon-generator-platformers-4/. Usado: em plataformas,
  poucas posições de porta e nenhum corredor; com ciclos, dezenas de segundos por nível; restrição a
  grafos acíclicos.
- Nutt, C. (2012, 13 abr.). *The secret to Mario level design* (entrevista a K. Hayashida). Game
  Developer. https://www.gamedeveloper.com/design/the-secret-to-i-mario-i-level-design. Usado: um
  conceito por nível; apresentar, desenvolver, reviravolta e concluir; planear primeiro a reviravolta
  e o final.
- Pullen, W. D. *Think Labyrinth: Maze Algorithms*. https://www.astrolog.org/labyrnth/algrithm.htm.
  Usado: labirintos perfeitos, entrançados e parcialmente entrançados; um entrançado bem feito pode
  ser mais difícil do que um perfeito.
- Taylor, D. (2013). *Ten Principles of Good Level Design*, partes 1 e 2. Game Developer, a partir da
  palestra no GDC 2013. https://www.gamedeveloper.com/design/ten-principles-of-good-level-design-part-1-
  e https://www.gamedeveloper.com/design/ten-principles-of-good-level-design-part-2-. Usado: dizer o
  que fazer e não como; o jogador controla a dificuldade com caminhos de risco anunciado; o nível
  nasce das mecânicas.
- Thompson, T. (2020, 3 jun.). *Bringing Balance to Stealth AI in Splinter Cell: Blacklist*. Game
  Developer. https://www.gamedeveloper.com/design/bringing-balance-to-stealth-ai-in-splinter-cell-blacklist.
  Resume o trabalho de M. Walsh (GDC 2014; *Game AI Pro 2*, cap. 28, não lido). Usado: deteção que
  acumula com o tempo; raios a vários pontos do corpo; plausível antes de inteligente; comunicar a
  intenção.
- *The Level Design Book*. https://book.leveldesignbook.com, páginas sobre refúgio e perspetiva,
  encontros, inimigos e wayfinding. Usado: a vista à entrada; com um só tipo de inimigo, a variedade
  vem da situação; primeiro os inimigos, depois os encontros, depois o espaço; zonas e marcos (Lynch).
  O livro mostra também que a teoria do refúgio e perspetiva (Appleton, 1975) tem base empírica fraca,
  razão pela qual este documento não se apoia nela.

Consultados e não usados:

- Aramini, Lanzi e Loiacono (2018), *An Integrated Framework for AI Assisted Level Design in 2D
  Platformers*, arXiv 1804.09153: só o resumo; a dificuldade de cada salto já se mede no README com a
  física do jogo.
- Biemer e Cooper (2022), *Level Assembly as a Markov Decision Process*, AIIDE 2022 (workshops),
  arXiv 2304.13922: monta a progressão segundo o desempenho do jogador, e a decisão G não adapta o
  nível ao jogador.
- Dormans e Bakkes (2011), *Generating Missions and Spaces for Adaptable Play Experiences*, IEEE
  Transactions on Computational Intelligence and AI in Games 3(3), pp. 216–228,
  DOI 10.1109/TCIAIG.2011.2149523: versão em revista do artigo de 2010; o que acrescenta, a adaptação
  ao jogador, não estava implementado no protótipo.
- Mawhorter, Ruslanova e Mawhorter (2022), *Representing Exploration in Metroidvania Games*, PCG
  Workshop: demonstração de um formato de grafo de salas, sem regras de desenho.
- Withington, Cook e Tokarchuk (2024), *On the Evaluation of Procedural Level Generation Systems*,
  FDG 2024, DOI 10.1145/3649921.3650016: analisa como a investigação avalia geradores, e não como
  avaliar o gerador de um jogo.

Identificados e não lidos: Smith, Cha e Whitehead (2008), *A Framework for Analysis of 2D Platformer
Levels*, Sandbox 2008, DOI 10.1145/1401843.1401858, a origem dos grupos de ritmo; Hullett e Whitehead
(2010), *Design Patterns in FPS Levels*, FDG 2010; Al-Omari, *The Impact of Consistency of Visual
Identity Elements in Digital Games on the Player's Experience*, DOI 10.18848/2325-1581/cgp/a181 (só
o resumo); Dormans (2017), *Cyclic Generation*, em *Procedural Generation in Game Design*, CRC Press,
pp. 83–96, a fonte primária do gerador cíclico; Mawhorter e Mateas (2010), *Procedural level
generation using occupancy-regulated extension*, IEEE CIG 2010, DOI 10.1109/ITW.2010.5593333 (só o
resumo em Shaker et al., 2016); Compton, K., *So you want to build a generator* (o sítio recusou o
acesso).

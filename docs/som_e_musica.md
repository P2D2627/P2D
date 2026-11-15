# Som e música

Este documento define a direção sonora do jogo, a música adaptativa, as regras técnicas e a lista de
sons, com o estado de cada ficheiro. Serve de referência ao grupo e de critério para rever cada
entrega. Os exemplos são do nível 1 (luxúria).

Nos termos usados, uma "camada" é uma faixa de música exportada em separado, que toca ao mesmo tempo
que as outras; um "loop" é um ficheiro que recomeça sem pausa quando acaba; um "compasso" é um grupo
fixo de tempos da música. O dBFS mede o pico de um ficheiro em relação ao máximo digital (0 dBFS), e o
LUFS mede o volume percebido.

## 1. Quem faz o quê

| Área | Responsável | Entrega |
|---|---|---|
| Música | Joaquim | as camadas e as variações de cada nível, em OGG |
| Efeitos sonoros e ambiente | Veríssimo | os efeitos da secção 5, em WAV, e o ambiente de cada nível, em OGG |
| Integração no Godot | por atribuir | a música adaptativa da secção 3 e a ligação de cada efeito ao seu evento |

## 2. Direção

- O tom é pesado. O humor negro vem só dos pecadores, nunca da fé, e o crucifixo soa sério e quente.
- Ambiente: a tempestade do segundo círculo, um vento contínuo que traz vozes ao longe, sugeridas e
  nunca explícitas.
- Música: lenta e dissonante, quente e sedutora, sobre um drone grave (uma nota grave contínua).
  Sugere-se instrumentação de época (alaúde, harpa, órgão, vozes), na linha do moodboard do Game
  Concept. Evitam-se os clichés de sedução, como o saxofone de bar. Um só tema, com outro arranjo em
  cada nível, dá unidade ao jogo e poupa trabalho.
- As ofertas de todos os bosses usam o mesmo motivo musical curto, com o timbre de cada boss: o
  jogador aprende a reconhecer a tentação pelo som.
- O SP baixo soa a um pulso grave, sem batimento de coração, porque ele já morreu.
- Os demónios avisam com som antes de se atirarem, para o jogador perceber sem olhar.
- Sem falas gravadas. O homem tem sons não verbais (esforço, dor, debater-se, acordar), e cada
  personagem que fala tem uma voz curta ao abrir cada fala.

## 3. Música adaptativa

### 3.1 Princípio

A música de cada nível é uma só peça, dividida em camadas que tocam sempre juntas e alinhadas. Em vez
de trocar de música, o jogo muda o volume de cada camada conforme o que acontece. Uma camada que entra
já estava a tocar em silêncio, e por isso entra a tempo em qualquer momento.

A perseguição também é uma camada. Um cão só começa a perseguir dentro do ecrã e desiste quando perde
o homem de vista ou pouco depois de sair do ecrã (`nivel1_desenho.md`, secção 7), pelo que as
perseguições começam e acabam muitas vezes. Uma música própria para a perseguição trocaria a cada
poucos segundos, enquanto uma camada sobe e desce sem cortes.

Há fases em que o jogador fica vários minutos, porque o nível é difícil. Para a música não se repetir,
a melodia tem 3 ou 4 variações do mesmo comprimento, e o Godot baralha a ordem em que tocam. A base (o
drone e a harmonia) repete-se, e a melodia por cima muda.

Quando o homem afunda ou morre e a sala recomeça, a música continua e só baixa durante esse momento.
Recomeçá-la a cada vez faria ouvir o início vezes sem conta, justamente nas salas mais difíceis.

Os momentos raros, como a oferta de um boss ou a morte, usam frases musicais à parte, que tocam
enquanto a peça baixa.

### 3.2 Camadas do nível 1 (proposta)

| Camada | O que leva | Quando se ouve |
|---|---|---|
| Drone | a nota grave contínua, que segura o centro tonal | sempre |
| Harmonia | os acordes ou a textura por cima do drone | sempre |
| Melodia | 3 ou 4 variações sorteadas (secção 3.4) | sempre, salvo nos momentos que a baixam |
| Tensão | um pulso ou uma textura inquieta, num registo que não tape os avisos dos cães | com um cão em alerta ou a perseguir |
| Perseguição | percussão | com dois ou mais cães a perseguir, e na corrida final até à tenda |

As três fases usam a mesma peça, e a intensidade sobe de fase para fase pela mistura das camadas. A
proposta afina-se ao compor.

### 3.3 Momentos do nível 1

| Momento | O que a música faz | P |
|---|---|---|
| Explorar, sem cães atrás do homem | drone, harmonia e melodia | P1 |
| Um cão em alerta ou a perseguir | entra a tensão; sai devagar depois de o último cão desistir, para não oscilar quando um cão vê e perde o homem várias vezes seguidas | P1 |
| Afundar ou morrer, e recomeçar a sala | a peça baixa e continua, sem recomeçar; a frase da morte é P2 | P1 |
| Oferta de um boss | a peça baixa e toca o motivo da tentação; o tema de Asmodeu por baixo é P2 | P1 |
| Dois ou mais cães a perseguir | entra também a perseguição | P2 |
| Agarrão e SP baixo | a música baixa para se ouvirem os avisos (secção 4, Buses) | P2 |
| Corrida até à tenda, no fim da fase 3 | todas as camadas | P2 |
| Perder o crucifixo | a música cala-se durante o momento, para que fique na memória | P2 |
| Cena inicial (a queda) | música própria | P3 |

### 3.4 Regras para compor

1. O andamento (BPM) e o compasso ficam fixos em toda a peça, sem automação de andamento. As camadas
   arrancam juntas e só se mantêm alinhadas se tiverem o mesmo andamento do princípio ao fim. O Godot
   usa ainda o Beat Count de cada ficheiro, em tempos, para saber onde acaba cada loop e cada variação.
2. A peça e cada variação têm um número inteiro de compassos e acabam no fim de um compasso.
3. Cada variação da melodia tem o comprimento do ciclo de acordes da base: 8 compassos, se a harmonia
   se repete a cada 8. Assim, qualquer variação encaixa em qualquer volta da base. O drone ajuda,
   porque mantém o centro tonal e deixa livre a ordem das variações.
4. Convém que uma das variações seja quase só pausa. O ouvido descansa, e a melodia seguinte nota-se
   mais.
5. Cada camada tem de soar bem por cima do drone e em cada combinação da tabela de momentos. As outras
   combinações não acontecem no jogo.
6. A peça compõe-se em blocos de 8 compassos. Se houver tempo depois da alpha, pode cortar-se em blocos
   sorteados sem ser recomposta.
7. Cada camada, e cada variação da melodia, tem a sua pista no mixer do FL Studio, com os efeitos na
   própria pista. O Master fica sem efeitos, porque na exportação por pistas os efeitos do Master só
   entram no ficheiro do próprio Master (manual do FL Studio). O limitador final fica no bus Music do
   Godot.
8. As camadas não se normalizam uma a uma, porque o equilíbrio entre elas é a mistura. Com todas a
   tocar, o pico fica até −1 dBFS.

### 3.5 Do FL Studio para o Godot

1. Exporta-se com a opção "Split mixer tracks", que gera um WAV por pista do mixer e só funciona em
   WAV. Os masters ficam em WAV de 24 bits, fora do repositório, com o projeto do FL Studio.
2. Nas camadas que repetem sozinhas, que são todas menos a melodia, a cauda exporta-se com "Wrap
   remainder": o FL Studio dobra o som que sobra no fim para o início do ficheiro, e o loop não corta o
   reverb. O manual avisa que a cauda de notas tocadas antes do último compasso não é dobrada.
3. Nas variações da melodia, a cauda exporta-se com "Leave remainder", que a deixa depois do fim. A
   documentação do Godot diz que o Beat Count marca o fim do áudio para o loop e para a lista, mesmo
   que o ficheiro seja mais comprido, e que a lista conta com esse bocado de som a mais para a
   transição durante o seu Fade Time. O teste da secção 3.7 confirma-o.
4. Cada WAV converte-se para OGG Vorbis, estéreo, a 44,1 kHz (o Audacity, por exemplo, exporta OGG).
5. Os nomes seguem o padrão `music_<nível>_<camada>.ogg`, e as variações `music_<nível>_melody_<n>.ogg`,
   por exemplo `music_lust_drone.ogg` e `music_lust_melody_2.ogg`. Ficam em
   `Projeto/assets/audio/music/`.
6. Na importação de cada OGG no Godot, preenchem-se o BPM, o Beat Count (o comprimento em tempos, sem
   a cauda) e o Bar Beats (os tempos por compasso). O Loop fica ligado nas camadas que repetem sozinhas
   e desligado nas variações da melodia, porque é a lista que repete.

### 3.6 No Godot

- As camadas que repetem sozinhas e a lista das variações juntam-se num `AudioStreamSynchronized`, que
  toca até 32 faixas a começar exatamente ao mesmo tempo. O jogo muda o volume de cada faixa com
  `set_sync_stream_volume`.
- As variações ficam num `AudioStreamPlaylist` com Shuffle e Loop ligados, e o Godot baralha a ordem
  de cada vez que a lista recomeça.
- As frases musicais (a oferta, a morte) tocam noutro `AudioStreamPlayer`, também no bus Music,
  enquanto a peça baixa.
- Os tempos de entrada e de saída de cada camada ficam expostos no Inspector e afinam-se a jogar.
- O `AudioStreamInteractive`, que troca de trecho no tempo ou no compasso seguinte, com fade, fica
  para os blocos sorteados de depois da alpha.

### 3.7 Por confirmar num teste

Antes de compor a peça inteira, um teste de 8 compassos, com 2 camadas e 2 variações da melodia, a
tocar uns 10 minutos seguidos, confirma o que a documentação do Godot e o manual do FL Studio não
dizem ou não garantem:

- se as pistas exportadas com "Split mixer tracks" saem com o mesmo comprimento e alinhadas;
- se o "Wrap remainder" se aplica a cada pista exportada em separado;
- se o loop das camadas toca sem estalido e sem quebra de volume na junção;
- se o volume de uma camada muda com a música a tocar;
- se uma lista de variações dentro do `AudioStreamSynchronized` fica alinhada com as outras camadas;
- em que ponto a lista troca de variação: no fim do Beat Count ou no fim do ficheiro.

Os 10 minutos servem para apanhar algum desvio que se acumule a cada troca de variação. Se a lista não
ficar alinhada, cada variação passa a levar as outras camadas, e a lista troca blocos completos. Os
resultados do teste registam-se nesta secção.

## 4. Regras técnicas

| Tipo | Formato | Notas |
|---|---|---|
| Efeitos (SFX) | WAV, 16 bits, 44,1 kHz, mono | 44,1 kHz é a taxa a que o Godot mistura por omissão; o que soa de um ponto do mundo é mono |
| Música e ambiente | OGG Vorbis, estéreo, 44,1 kHz | o loop liga-se na importação do Godot; o OGG só repete para a frente, por isso o fim tem de ligar ao início sem clique |
| Masters | WAV de 24 bits | fora do repositório, como os da arte |

A documentação do Godot recomenda WAV para efeitos curtos e repetidos e OGG Vorbis para música, falas
e efeitos longos.

- Volume: os picos de cada ficheiro ficam até −1 dBFS. Os ficheiros da mesma categoria normalizam-se
  para o mesmo valor em LUFS; na música, mede-se a peça inteira, com todas as camadas a tocar, e nunca
  cada camada sozinha (secção 3.4). O equilíbrio entre categorias faz-se nos buses do Godot. Para a
  mistura final, a referência da indústria é a da Sony (ASWG-R001, 2013), que a Microsoft e a Nintendo
  seguiram depois (Bridgett, 2015): −24 LUFS para jogos de casa e −18 LUFS para portáteis, medidos a
  jogar numa sessão longa, de pelo menos 30 minutos (Taylor, 2012).
- Variações: os sons que se repetem muito (passos, salto, aterragem) têm 3 a 5 versões, sorteadas sem
  repetir a anterior. Os passos do homem já são sorteados por código, com o volume a variar 1%
  (`player_sounds.gd`). Nos sons novos, o AudioStreamRandomizer faz o mesmo sem código e varia também o
  tom (Random Pitch = 1,05, cerca de 5% para cima ou para baixo).
- Buses: Master, Music, SFX, Ambience e UI, já criados no projeto, com volumes separados nas opções.
  A música baixa quando toca um aviso importante, como o agarrão ou o SP baixo (P2). Para os passos e
  os outros efeitos não a baixarem também, os avisos tocam num bus próprio, que é o único que o
  compressor do bus Music escuta (sidechain). A alternativa é baixar a música por código.
- Nada de essencial depende só do som: cada aviso sonoro tem um sinal visual. Nas opções, uma opção de
  som mono (P3) deixa quem ouve só de um lado ouvir também o que soa desse lado.
- Origem: no Freesound, só sons CC0 ou CC BY (o CC BY obriga a citar o autor); evitam-se o CC BY-NC
  e o Sampling+. Os assets da Kenney são CC0, livres mesmo em uso comercial. A licença tem de cobrir o
  jogo, o vídeo, as apresentações e o portefólio. Som gerado por IA é permitido na cadeira e regista-se
  da mesma maneira nos Créditos do README.

## 5. Lista de sons

Os estados são: por fazer; provisório, quando o ficheiro existe mas ainda não cumpre a secção 4 ou
falta revê-lo; e final. Refletem os ficheiros do repositório a 2026-11-10.

O homem:

| Evento | Som | Versões | Reuso | P | Estado |
|---|---|---|---|---|---|
| Passo a correr | passo curto, que acaba antes do seguinte: a 720 px/s, com um passo a cada 220 px, há um passo a cada 0,31 s; cada nível pode juntar uma camada do seu chão (P3) | 4 | partilhado | P1 | provisório: `footstep_1` a `footstep_3` (3 de 4) |
| Salto | impulso e roupa | 3 | partilhado | P1 | provisório: `player_jump` (1 de 3) |
| Aterragem | impacto curto | 3 | partilhado | P1 | provisório: `soft_land` (1 de 3) |
| Deslizar na parede | atrito, em loop | 1 | partilhado | P1 | provisório: `wall_slide` |
| Salto da parede | impulso e mão na rocha | 2 | partilhado | P1 | por fazer |
| Erguer e baixar o crucifixo | | 1 e 1 | partilhado | P1 | provisório: `crucifix_raise` e `crucifix_holster` |
| Crucifixo erguido | tom contínuo, quente, em loop | 1 | partilhado | P1 | provisório: `crucifix_hold_loopable` |
| Crucifixo: recarga e disponível outra vez | | 1 e 1 | partilhado | P1 | provisório: `crucifix_cd` e `crucifix_avail` |
| Crucifixo: indisponível | | 1 | partilhado | P1 | provisório: usa o `upgrade_unavail` |
| Perder SP | a alma a fugir, sem sangue | 3 | partilhado | P1 | por fazer |
| SP baixo | pulso grave, em loop | 1 | partilhado | P1 | provisório: `low_sp`, ainda fora do jogo |
| Agarrado | os demónios da luxúria a envolvê-lo | 2 | único | P1 | por fazer |
| Cada toque para se soltar | curto; o tom sobe com o progresso, por código | 1 | partilhado | P1 | por fazer |
| Soltar-se | | 2 | partilhado | P1 | por fazer |
| Morrer e recomeçar | | 1 e 1 | partilhado | P1 | por fazer |
| Checkpoint a acender | | 1 | partilhado | P1 | por fazer |
| Queda da cena inicial | vento a passar, longo | 1 | único | P1 | por fazer |
| Bater no chão e acordar | | 1 | único | P1 | por fazer |
| Aterragem pesada | impacto grave | 2 | partilhado | P2 | provisório: `hard_land` e `hard_land_2` |
| Cura do crucifixo | | 1 | partilhado | P2 | por fazer |
| Voz não verbal | esforço, dor, debater-se, gemer ao acordar | 3, 3, 3 e 1 | partilhado | P2 | por fazer |

Demónios, bosses e escolhas:

| Evento | Som | Versões | Reuso | P | Estado |
|---|---|---|---|---|---|
| Demónio perto do homem | respiração e sussurros sedutores, sugeridos | 3 | único | P1 | por fazer |
| Alerta: o cão vê o homem | curto e reconhecível | 1 | único | P1 | provisório: `demon_alert`, bip sintético |
| Procura: o cão perdeu-o de vista | | 1 | único | P1 | provisório: `demon_search`, bip sintético |
| Aviso antes de se atirar | curto e reconhecível | 2 | único | P1 | por fazer |
| Atirar-se | | 2 | único | P1 | provisório: `demon_take_off`, bip sintético (1 de 2) |
| Aterrar depois de se atirar | | 1 | único | P1 | provisório: `demon_land`, bip sintético |
| Repelido pelo crucifixo | | 2 | único | P1 | por fazer |
| Arrastar-se atrás dele | | 3 | único | P2 | por fazer |
| Atirado para trás | | 2 | único | P2 | por fazer |
| Demónio do tutorial a falar | voz curta | 3 | único | P1 | por fazer |
| Asmodeu a falar | sussurro curto | 3 | único | P1 | por fazer |
| Oferta de um boss | o motivo da tentação, com o timbre do boss | 1 | variante | P1 | por fazer |
| Aceitar o atalho | acompanha a passagem a preto | 1 | partilhado | P1 | por fazer |
| Receber um upgrade | | 1 | variante | P1 | por fazer |
| Perder o crucifixo | acontece uma vez no jogo, no primeiro upgrade aceite; é o momento do tema "Destroy Yourself" e tem de ficar na memória | 1 | partilhado | P1 | por fazer |
| Asmodeu recusada | | 1 | único | P2 | por fazer |
| Boss a aparecer e a desaparecer | | 1 e 1 | variante | P2 | por fazer |

Ambiente, interface e música:

| Evento | Som | Versões | Reuso | P | Estado |
|---|---|---|---|---|---|
| Ambiente do nível | a tempestade, em loop de 1 a 2 minutos, estéreo | 1 | único | P1 | por fazer |
| Vozes levadas pelo vento | camada à parte do ambiente | 1 | único | P2 | por fazer |
| Sons localizados | tecido a bater, por exemplo | 2 a 3 | único | P3 | por fazer |
| Avançar o texto, escolher, confirmar | | 1 cada | partilhado | P1 | por fazer |
| Abrir e fechar a pausa e o diálogo | | 1 cada | partilhado | P2 | por fazer |
| Música do nível: drone, harmonia e melodia | secção 3 | 3 ou 4 variações da melodia | variante | P1 | por fazer |
| Música do nível: tensão | secção 3 | 1 | variante | P1 | por fazer |
| Música do nível: perseguição | secção 3 | 1 | variante | P2 | por fazer |
| Tema de Asmodeu, nas ofertas | loop curto | 1 | único | P2 | por fazer |
| Morte | frase musical curta | 1 | partilhado | P2 | por fazer |
| Música da cena inicial | | 1 | único | P3 | por fazer |

Ficheiros sem evento:

- `hit.wav`: está fora do jogo e não corresponde a nenhum evento da lista. Pode servir para Perder SP;
  decide-se com o Veríssimo.
- `crucifix_hold.wav`: está fora do jogo e parece uma versão anterior do `crucifix_hold_loopable.wav`.

## 6. Revisão dos ficheiros existentes

Medição feita a 2026-11-10 aos 21 WAV que hoje estão em `Projeto/assets/audio/sfx/`, com um script que lê o cabeçalho e
as amostras de cada ficheiro. Todos estão a 44,1 kHz. Nos canais, "2 (iguais)" quer dizer que os dois
canais têm as mesmas amostras. O início do som conta até o sinal passar 40 dB abaixo do pico do próprio
ficheiro. Nos loops, a junção dá o volume médio (RMS) dos primeiros 50 ms, dos últimos 50 ms e do
ficheiro inteiro; uma ponta muito abaixo da média indica uma quebra na junção. São medidas simples,
que não substituem ouvir.

| Ficheiro | Formato | Canais | Duração (s) | Pico (dBFS) | Início do som (ms) | Junção do loop: início / fim / média (dBFS) | Fora da regra |
|---|---|---|---|---|---|---|---|
| `crucifix_avail` | PCM 16 bits | 2 | 1,48 | −27,7 | 47 | | estéreo |
| `crucifix_cd` | PCM 16 bits | 2 | 0,97 | −24,3 | 0 | | estéreo |
| `crucifix_hold` | float 32 bits | 2 | 14,24 | −10,8 | 0 | −41,0 / −64,9 / −25,9 | estéreo, float |
| `crucifix_hold_loopable` | PCM 16 bits | 2 | 5,15 | −17,1 | 0 | −47,3 / −33,9 / −31,7 | estéreo |
| `crucifix_holster` | PCM 16 bits | 2 | 0,51 | −21,9 | 1 | | estéreo |
| `crucifix_raise` | PCM 16 bits | 2 | 0,22 | −21,0 | 1 | | estéreo |
| `demon_alert` | PCM 16 bits | 1 | 0,14 | −7,8 | 0 | | nada |
| `demon_land` | PCM 16 bits | 1 | 0,14 | −8,0 | 0 | | nada |
| `demon_search` | PCM 16 bits | 1 | 0,28 | −7,9 | 0 | | nada |
| `demon_take_off` | PCM 16 bits | 1 | 0,12 | −7,9 | 0 | | nada |
| `footstep_1` | PCM 16 bits | 2 | 0,25 | −19,2 | 0 | | estéreo |
| `footstep_2` | PCM 16 bits | 2 | 0,27 | −24,2 | 0 | | estéreo |
| `footstep_3` | PCM 16 bits | 2 | 0,28 | −18,4 | 0 | | estéreo |
| `hard_land` | float 32 bits | 2 (iguais) | 0,38 | −19,1 | 1 | | estéreo, float |
| `hard_land_2` | float 32 bits | 2 | 0,58 | −19,8 | 1 | | estéreo, float |
| `hit` | float 32 bits | 2 | 0,38 | −22,1 | 0 | | estéreo, float |
| `low_sp` | PCM 16 bits | 2 (iguais) | 2,19 | −9,9 | 68 | −69,2 / −78,7 / −20,6 | estéreo |
| `player_jump` | float 32 bits | 2 (iguais) | 0,28 | −19,1 | 0 | | estéreo, float |
| `soft_land` | float 32 bits | 2 (iguais) | 0,22 | −19,9 | 0 | | estéreo, float |
| `upgrade_unavail` | PCM 16 bits | 2 | 1,50 | −16,0 | 0 | | estéreo |
| `wall_slide` | float 32 bits | 2 | 3,43 | −17,1 | 0 | −33,5 / −32,5 / −31,9 | estéreo, float |

O que a medição mostra:

- Nenhum ficheiro passa de −1 dBFS.
- Dezassete ficheiros estão em estéreo, e a regra pede mono. Só os quatro bips provisórios dos
  demónios estão em mono. Quatro dos ficheiros em estéreo têm os dois canais iguais, e nesses a
  passagem a mono não muda o som; nos outros, convém ouvir o resultado.
- Sete ficheiros estão em 32 bits de vírgula flutuante (float), e a regra pede 16 bits. A passagem a
  16 bits, como a passagem a mono, faz-se em lote e não obriga a refazer os sons.
- Os três passos (0,25 a 0,28 s) acabam antes do passo seguinte, que vem a cada 0,31 s.
- O `footstep_2` tem o pico 5 a 6 dB abaixo dos outros dois passos. O pico não é o volume percebido,
  mas num sorteio pode notar-se um passo mais fraco.
- O `crucifix_avail` só começa 47 ms depois do início do ficheiro. Os outros sons curtos começam no
  primeiro milissegundo.
- O `crucifix_cd` começa numa amostra a metade do pico, o que pode dar um estalido no arranque.
- Nas junções dos loops, o `wall_slide` mantém o volume. No `crucifix_hold_loopable`, que está no
  jogo, os primeiros 50 ms ficam cerca de 15 dB abaixo da média, e a quebra deve ouvir-se a cada
  5,15 s. O `low_sp` tem silêncio nas duas pontas, o que é normal num pulso; falta ouvir se o ritmo se
  mantém na junção.
- Os picos vão de −7,8 dBFS (os bips) a −27,7 dBFS (`crucifix_avail`). O equilíbrio entre famílias de
  sons ouve-se no jogo.
- Estão fora do jogo o `crucifix_hold.wav`, o `hit.wav` e o `low_sp.wav`.
- Nos Créditos do README só estão os quatro bips. Se algum dos outros 17 ficheiros usa material de
  terceiros, regista-se lá com a origem e a licença.
- Os efeitos estão em `assets/audio/sfx/` desde a reorganização das pastas (PR #242). A música entra
  em `assets/audio/music/` (secção 3.5).

O que se refaz combina-se com o Veríssimo, a partir desta revisão e da audição no jogo.

## 7. Referências

- Godot Engine 4.7, *Importing audio samples*:
  https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html. Usado:
  WAV para efeitos curtos e repetidos, OGG Vorbis para música, falas e efeitos longos.
- Godot Engine 4.7, referência das classes `AudioStreamSynchronized`, `AudioStreamPlaylist`,
  `AudioStreamInteractive` e `AudioStreamOggVorbis`, consultada a 2026-11-10:
  https://docs.godotengine.org/en/stable/classes/class_audiostreamsynchronized.html,
  https://docs.godotengine.org/en/stable/classes/class_audiostreamplaylist.html,
  https://docs.godotengine.org/en/stable/classes/class_audiostreaminteractive.html e
  https://docs.godotengine.org/en/stable/classes/class_audiostreamoggvorbis.html. Usado: até 32 faixas
  que começam ao mesmo tempo, com volume por faixa; a lista com Shuffle, Loop e Fade Time, que conta
  com som a mais no fim de cada ficheiro; as trocas de trecho no tempo, no compasso ou no fim; o Beat
  Count como fim do áudio para o loop, para a lista e para a música interativa.
- Godot Engine 4.7, referência das classes `AudioStreamRandomizer` e `AudioEffectCompressor`:
  https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html e
  https://docs.godotengine.org/en/stable/classes/class_audioeffectcompressor.html. Usado: o sorteio de
  variações e o compressor com sidechain da secção 4.
- Image-Line, manual do FL Studio, *Exporting Audio & MIDI*, consultado a 2026-11-10:
  https://cluster.image-line.com/fl-studio-learning/fl-studio-online-manual/html/fformats_save_export.htm.
  Usado: "Split mixer tracks" exporta um WAV por pista do mixer, só em WAV; os efeitos do Master só
  entram na exportação do Master; "Wrap remainder", "Leave remainder" e o aviso sobre a cauda das
  notas tocadas antes do último compasso.
- Taylor, G. (2012), entrevista ao Designing Sound sobre o volume de referência da Sony:
  https://designingsound.org/2012/07/30/video-games-and-loudness-standards-interview-with-sonys-garry-taylor/.
  Usado: medir o jogo durante pelo menos 30 minutos.
- Bridgett, R. (2015), artigo na Audio Media International sobre o volume nos jogos para telemóvel:
  https://audiomediainternational.com/mobile-loudness-an-adaptive-approach/. Usado: o documento da Sony
  adotou −24 LUFS, com −18 LUFS para portáteis, e a Microsoft e a Nintendo seguiram depois as mesmas
  recomendações.
- Freesound, FAQ: https://freesound.org/help/faq/. Usado: as licenças da secção 4, Origem.
- Kenney, Support: https://kenney.nl/support. Usado: os assets da Kenney são CC0.

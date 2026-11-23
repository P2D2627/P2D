# 8. Playtests e iteração

O que se testou com jogadores, o que se viu, o que mudou no design e porquê, por data, e os testes seguintes. A ficha da cadeira pede pelo menos uma solução proposta e validada para um problema: a validação fica registada aqui.

Dono: [por decidir pelo grupo] · Revisto: 2026-11-23 · Estado: a meio (dados do piloto e registo das mudanças; leitura do grupo e critérios de sucesso por fechar)

## Como se testa

Cada playtest tem uma hipótese, o que se observa e um critério de sucesso, escritos antes de começar. O jogo grava, por partida, cada morte (causa, fase e zona), o tempo e cada oferta: aceite ou recusada, e quanto tempo o jogador a ouviu.

## Piloto: Aveiro Tech Week, 20/11/2026

Build do nível 1, jogada por visitantes do evento. Os questionários não chegaram a ser usados. Os dados são os registos do jogo; as notas de cada observador estão por preencher. [por escrever pelo grupo]

| Bloco | Minutos | Mortes | Onde mais morreu | Ofertas, por ordem |
|---|---|---|---|---|
| 1 | 16 | 12: 8 em picos, 4 por demónios | P2OverStep (6); fases 1 e 2 | Recusou o atalho aos 10 min e aceitou-o aos 15; recusou o dom |
| 2 | 26 | 52, todas em picos | Fase 3 (47): P3SLeft (25) e P3DropShaft (18) | Aceitou o atalho no 1.º minuto e o dom no 2.º; recusou um atalho; aceitou outro aos 11 min; recusou o dom |
| 3 | 14 | 13: 10 em picos, 3 por demónios | P2OverStep (8); fases 1 e 2 | Recusou o atalho três vezes e aceitou-o à quarta, aos 13 min; recusou o dom |

Validade:

- Estavam previstos 5 a 15 visitantes e vieram 2, segundo o plano de avaliação. Os registos têm três blocos, sem código de jogador, e um bloco pode juntar várias partidas. [por confirmar pelo grupo: de quem é cada bloco; um bloco que tenha sido de um membro do grupo sai da tabela]
- Os visitantes de uma mostra do mestrado não são a persona, e o sítio era ruidoso. O piloto testa os instrumentos e dá os primeiros sinais; não mede os critérios de sucesso.

O que os registos mostram:

- 70 das 77 mortes foram em picos.
- As mortes juntam-se em três zonas: P2OverStep (14, nos blocos 1 e 3), P3SLeft e P3DropShaft (43, no bloco 2).
- Os três blocos aceitaram pelo menos um atalho; dois deles só depois de o recusarem uma a três vezes.
- No bloco 3, as recusas vieram ao fim de 1 a 6 s de oferta.
- O grupo registou um erro: com a alma em cima de um cão, erguer o crucifixo afasta o cão e leva a alma com ele (sem issue própria a 23/11).

Leitura, por validar nos testes seguintes: os picos leem-se mal; parte dos jogadores salta o texto das ofertas. Nos blocos 1 e 3, o atalho foi aceite ao fim de 13 a 15 minutos, depois de recusas, como o design pretende; no bloco 2, logo no primeiro minuto, antes de qualquer frustração. [por rever pelo grupo]

## Outros testes

- 21/11, um jogador de fora do grupo, familiar de um membro: jogou uma hora e parou a meio da fase 2. Pediu mais pontos de gravação nos portões, porque o jogo cansa quem não joga muito, e disse que os picos são todos iguais e difíceis de perceber.
- 21 e 22/11, o grupo a jogar a build de teste: o som de quem está prestes a morrer fica áspero quando a distorção sobe; a câmara que segue a alma deu dores de cabeça e enjoo a alguns.

## Registo datado das mudanças de design

| Data | O que mudou | Porquê |
|---|---|---|
| 29/09/2026 | A primeira ideia do grupo dá lugar aos sete pecados | Os docentes acharam-na batida |
| 11/11 | A alma fica mais calma e pesada: 600 px/s de corrida, subida do salto em 0,45 s, queda rápida | A personagem parecia hiperativa e leve, e os docentes jogaram melhor com o jogo todo a 0,75× |
| 15/11 | Sem rato: joga-se só com o teclado ou só com o comando, e os poderes herdam o botão do crucifixo | Ninguém do grupo se adaptou ao crucifixo no rato; com o mesmo botão, o jogador não aprende outro ao aceitar o primeiro dom |
| 16 a 18/11 | O nível passa a escuro, iluminado por luzes 2D: protótipo a 16/11, no jogo a 18/11 | Os cães apareciam e esbatiam-se pela linha de vista sem nada no ecrã que o explicasse; a escuridão dá-lhe uma razão visual |
| 17/11 | O crucifixo passa a bateria: 5 s de carga, 15 s a encher, e um uso curto custa só o seu tempo | Um toque curto custava tanto como um uso inteiro, e não compensava usá-lo pouco |
| 17/11 | As silvas podem prender e matar devagar (Catches), em vez de matar ao toque; hoje está desligado por defeito | Morrer de repente parecia fraco: o jogador devia sentir-se preso e achar que ainda podia fugir, sem ter de carregar depressa num botão |
| 18/11 | Três slots de gravação, com gravação automática | Partidas separadas no menu, com Continue e Load |
| 20/11 | A personagem passa a ser uma alma sem passado e sem género, com o nome escrito pelo jogador | O herói é o jogador: o julgamento compara o que ele disse com o que fez |
| 20/11 | O cão maior segue o rasto da alma, e a saída só abre depois do caminho de volta | O cão ia sempre direito à alma, e nada obrigava ao caminho de volta |
| 21/11 | Câmara fixa ao lado da antiga, trocável com F10 | Piloto: rocha a mais no ecrã, zoom a mudar em fronteiras que o jogador não vê, alma fora do centro |
| 22/11 | A câmara fixa passa a predefinida, mais suave, com a alma mais alta no ecrã nas descidas | Testes do grupo: dores de cabeça e enjoo |
| 22/11 | O cão maior mata num golpe, corre a 550 px/s, salta para a plataforma da alma com 0,35 s de aviso e o crucifixo não o afasta | Em playtest, lia-se como fraco: o crucifixo atirava-o para trás e, com a alma noutra plataforma, ficava a ladrar por baixo |
| Por decidir | Mais pontos de gravação e picos mais legíveis | Piloto e teste de 21/11. [por decidir pelo grupo: contra a dificuldade de propósito] |

## Próximos testes

Calendário do plano de avaliação: em dezembro, duas rondas com 5 a 6 jogadores do público-alvo cada e uma revisão de especialistas dos níveis 1 e 2; em janeiro, um grupo de foco e um novo teste das correções.

| Hipótese | O que observar | Critério de sucesso [proposta] |
|---|---|---|
| Com picos mais legíveis, as mortes neles descem | Mortes por causa e por zona, nos registos; o que o jogador diz ao morrer | Picos abaixo de metade das mortes, e nenhuma zona com mais de um quarto delas |
| A oferta chega quando o jogador está prestes a desistir | Hesitação e comentários em cada oferta; tempo a ouvi-la | Quem aceita refere cansaço ou frustração na entrevista a seguir |
| A câmara fixa causa menos enjoo do que a que segue a alma | Queixas de enjoo e de rocha a mais, com cada câmara (F10) | Nenhuma queixa de enjoo com a câmara fixa |

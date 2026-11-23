# 6. Arte e áudio

Como o jogo se vê e soa: a direção, a legibilidade, a cor e a luz, os efeitos, a produção dos assets, a música, os sons, a mistura e a vibração.

Dono: [por decidir pelo grupo] · Revisto: 2026-11-23 · Estado: a meio (arte dos níveis 2 e 3 por decidir; música do nível 1 por entrar no jogo)

## Arte

### Direção

- Arte 2D ilustrada, sem pixel art (proposta inicial do projeto, 15/09/2026).
- O inferno é o que a alma imagina, mais perto de Dante do que da Bíblia. O tom é pesado; o humor negro vem dos demónios e dos pecadores, nunca da fé.
- Referências de ambiente: Bosch e as gravuras de Doré para a *Divina Comédia*. Dão o ambiente, a forma dos demónios e a composição; o estilo é do grupo.
- Nível 1: o segundo círculo do Inferno de Dante, onde uma tempestade nunca para. As rampas de cor do jogo são a da luxúria e duas de laranja, uma escura e uma dourada, em `Projeto/assets/sprites/ramps/`.
- No nível da luxúria tudo é sugerido, sem nudez.
- O plano de arte evitava o fogo e as forquilhas, as imagens mais esperadas de um inferno. Desde 16/11/2026, as fogueiras são as fontes de luz do nível 1; as forquilhas continuam de fora.

### Legibilidade

- O que mata ou se usa lê-se pela silhueta e pelo contraste entre claro e escuro, antes da cor. Teste: uma captura a preto e branco e em miniatura continua jogável. [por fazer: o teste nas capturas do nível 1]
- O fundo é mais escuro e menos saturado do que o plano onde se joga.
- Os estados leem-se pela forma e pela luz, nunca só pela cor. Por exemplo, a estátua dos portões fica apagada até ser usada e ganha uma chama depois.
- Os cães avisam cada ataque pela forma do corpo: alargam e baixam antes da mordida, param e encolhem antes do salto ([bloco 2](2_gameplay_and_rules.md)).

### Cor e luz

- O cenário pinta-se em cinzentos, do quase preto ao quase branco. Cada camada leva a rampa de cor do nível, que troca cada cinzento por uma cor, e os mesmos tiles servem os três níveis. As camadas mais distantes levam rampas mais escuras e menos saturadas.
- O fundo tem quatro camadas com parallax: Far (0,25), Middle (0,5), Near (0,75) e Front (1,2). Detalhe no [README](../../README.md), "Fundo em camadas".
- O nível 1 é escuro e iluminado pelas luzes 2D do Godot: as fogueiras, no nível e no fundo, e uma aura à volta da alma. O New Game abre o nível com esta iluminação.
- O que a alma vê decide-se pela linha de vista, não pela luz: um cão aparece quando a alma o vê ou quando ele a vê, e esbate-se quando deixa de ser visto. A escuridão dá a essa regra uma razão no ecrã. Detalhe no [README](../../README.md), "Linha de vista".

### Efeitos

| Momento | Efeito |
|---|---|
| Morte e recomeço | O ecrã escurece até ao preto e clareia em 0,35 s no último ponto de gravação. Uma íris sobre o corpo existe no código, desligada por defeito |
| Morte nas silvas | O jogo congela 0,1 s e as silvas puxam a alma para dentro em 0,6 s |
| Tempestade | Relâmpagos, brasas levadas pelo vento, névoa de distância e raios de luz |
| Pancadas | Tremor do ecrã que se soma e desce, regulável de 0 a 100 % nas opções |
| Menus | Fumo e brilho de fogo |

### Medidas e produção

- Grelha de 48 px. A alma ocupa 48 × 96 px (1 × 2 tiles); os cães, 112 × 56, 140 × 70 e 168 × 84 px.
- Desenha-se ao dobro e exporta-se a 1×, para 1920 × 1080, em PNG com fundo transparente. Cada personagem desenha-se virada para a direita, e o jogo espelha-a. Os pés pousam sempre na mesma linha da célula. Nenhuma imagem passa de 4096 px de lado.
- Os ficheiros de trabalho (`.kra`, `.psd`) ficam numa pasta partilhada, fora do repositório, enquanto não houver Git LFS.
- Nomes em inglês, em minúsculas e com `_`; uma pasta por grupo em `Projeto/assets/sprites/`.

### Estado dos assets (23/11/2026)

| No jogo | Provisório | De terceiros |
|---|---|---|
| Alma, cães, Velvet a andar, Asmodeus, fogueiras animadas, silvas, lajes, portão e estátua, barra de alma do HUD, arte do menu | Fundo do nível 1, feito a partir do mapa do nível | Ícones dos botões (CC0) e três famílias de letra (SIL Open Font License) |

Origem e licença de cada ficheiro: secção Créditos do [README](../../README.md).

Por decidir pelo grupo: o estilo e as rampas dos níveis 2 e 3, os retratos definitivos e a forma do ponto de gravação.

## Áudio

### Direção

- O tom é pesado. O crucifixo soa sério e quente.
- Ambiente do nível 1: a tempestade do segundo círculo, com vento contínuo, rajadas, trovões e vozes ao longe, sugeridas e nunca explícitas.
- Música lenta e dissonante, sobre uma nota grave contínua (drone). Um só tema, com outro arranjo em cada nível, composto em FL Studio.
- As ofertas de todos os senhores usam o mesmo motivo curto, com o timbre de cada um, para o jogador reconhecer a tentação pelo som.
- O SP baixo soa a um pulso grave, sem batimento de coração, porque a alma já morreu.
- Sem falas gravadas. A alma tem só sons não verbais (esforço, dor, debater-se); cada personagem que fala tem uma voz curta no início de cada fala.

### Música por camadas

Cada nível tem uma só peça, dividida em camadas que tocam sempre juntas: drone, harmonia, melodia (3 ou 4 variações do mesmo comprimento, em ordem sorteada), tensão e perseguição. O jogo muda o volume de cada camada conforme o que acontece: um cão em alerta traz a tensão, e dois ou mais a perseguir trazem a percussão. Quando a alma morre, a música baixa e continua, para o início não se ouvir vezes sem conta nas salas difíceis.

Estado: no jogo há o tema do menu; as camadas do nível 1 estão desenhadas e por entrar no jogo. Detalhe em [som e música](../som_e_musica.md), secção 3.

### Sons e mistura

- Grupos de mistura (buses): Music, SFX, Ambience, UI e Alerts, com subgrupos para os fundos, as rajadas e os trovões do ambiente e para os sons da alma e dos demónios.
- Os sons que se repetem sorteiam uma variação, sem repetir a anterior.
- Nada de essencial depende só do som: o alerta do cão toca com um "!" por cima da cabeça, e cada ataque tem um aviso de forma.
- Os menus respondem a mover, escolher, voltar e recusar com sons próprios, à intensidade de cada evento.
- Volumes separados nas opções: geral, música, efeitos, ambiente e interface ([bloco 5](5_flow_interface_controls.md)).
- Referência de loudness: −24 LUFS, medidos a jogar numa sessão longa ([som e música](../som_e_musica.md), secção 4). Falta medir o jogo.
- Lista de sons, com o estado de cada um: [som e música](../som_e_musica.md), secção 5. Provisórios: os bips de alerta, procura, salto e aterragem dos demónios e dois sons de cão feitos a partir dos da alma (README, Créditos).

### Vibração

A vibração do comando segue o corpo da alma, numa escada de quatro degraus de intensidade, e regula-se de 0 a 100 % nas opções; os menus também vibram. Detalhe no [README](../../README.md), "Vibração do comando".

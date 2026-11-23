# 7. Técnica e produção

Como o jogo está construído e como a equipa trabalha: a técnica, a produção, a escolha do motor, os papéis, os riscos e os protótipos. O detalhe técnico está no [README](../../README.md), secção "Para quem programa".

Dono: [por decidir pelo grupo] · Revisto: 2026-11-23 · Estado: a meio

## Técnica

| Tema | Decisão |
|---|---|
| Motor | Godot 4.7, GDScript tipado, renderer Compatibility (mantém abertos o móvel e a web). Critérios da escolha: secção seguinte |
| Ecrã | Viewport de 1920 × 1080, escala `canvas_items`, aspeto `expand` |
| Estrutura | Em `Projeto/scenes/`, por tipo: `autoload/`, `characters/`, `levels/`, `objects/`, `others/` e `screens/` |
| Cena principal | `Main`, com o `LevelSlot` onde entra o nível, o menu e a pausa; os menus só emitem sinais |
| Serviços globais | `Settings` (opções), `GameState` (estado da partida), `RunStats` (estatísticas), `Offers` (ofertas), `Moral` (registo moral), `DialogueManager` (falas), `LastDevice` (último aparelho usado, para os avisos) |
| Regras de jogo | Em classes puras, testadas sem a cena: registo moral, ritmo das ofertas, gravações |
| Afinação | Em ficheiros de dados (`.tres`), editáveis no Inspector; uma oferta nova é um ficheiro novo, sem código novo |
| Testes | Um script por coisa testada em `Projeto/tests/`, com código de saída 0 quando passa; smoke test do projeto inteiro |

## Produção

| Tema | Como é |
|---|---|
| Método | Scrum, sprints de duas semanas, estimadas em pontos (1 ponto ≈ 2 horas de trabalho) |
| Backlog | Issues do GitHub, agrupadas em milestones: Game Concept, sprints, Alpha Version, Final Version |
| Quadro | Backlog → In Progress → In Review → Done |
| Ramos | Cada feature num ramo próprio a partir do `dev`; entra por pull request revisto por um colega. O `main` deve receber o `dev` nos marcos; não o recebe desde 3/11/2026. [por decidir pelo grupo] |

## Escolha do motor

O Godot já vinha na primeira proposta do projeto (15/09/2026), e o grupo não registou os critérios da escolha. A matriz seguinte foi feita a 23/11/2026, com os critérios de decisão de motores da cadeira de Conceção e Desenvolvimento de Jogos, e documenta a escolha depois de feita. [por rever pelo grupo: pesos e notas]

Peso de 1 a 3; nota de 1 a 5 por motor.

| Critério | Peso | Godot | Unity | GameMaker | Porquê |
|---|---|---|---|---|---|
| Serve o género (plataformas 2D) | 3 | 5 | 4 | 5 | Os três fazem 2D; o Unity faz 2D sobre um motor pensado para 3D |
| Ferramentas 2D (tiles, luzes 2D, física) | 3 | 5 | 4 | 4 | O Godot traz tiles, luzes e sombras 2D de origem |
| Curva de aprendizagem para a equipa | 2 | 4 | 4 | 4 | Cada motor pede uma linguagem nova a parte da equipa |
| Plataformas de exportação | 1 | 4 | 5 | 5 | PC chega para a alpha; as consolas pedem ajuda de terceiros no Godot |
| Licença e custo | 3 | 5 | 3 | 3 | Godot: licença MIT, sem custos nem royalties. Unity: o Personal é gratuito até 200 000 USD de receita, depois paga-se por lugar; a taxa por instalação anunciada em 2023 foi cancelada em setembro de 2024. GameMaker: gratuito para uso não comercial; vender pede uma licença de 99,99 USD, paga uma vez |
| Comunidade e documentação | 2 | 4 | 5 | 3 | O Unity tem a maior base de tutoriais; a do Godot cresce e a documentação oficial é aberta |
| Fluxo de equipa e Git | 3 | 4 | 3 | 3 | As cenas e os recursos do Godot são texto legível, e os conflitos resolvem-se no próprio ficheiro; as cenas do Unity, em YAML, pedem uma ferramenta de junção própria |
| **Total** (máximo 85) | | **77** | **65** | **64** | |

A ordem mantém-se sem o critério da licença (62, 56 e 55) e com todos os pesos iguais (31, 28 e 27).

Fontes, lidas a 23/11/2026: [licença do Godot](https://godotengine.org/license/); [Unity, cancelamento da Runtime Fee](https://unity.com/blog/unity-is-canceling-the-runtime-fee) (12/09/2024); [GameMaker, licenças](https://gamemaker.io/en/get).

## Papéis

Cinco pessoas, com papéis que se sobrepõem. [por confirmar pelo grupo]

| Pacote de papéis |
|---|
| Direção da equipa, arte de conceito e efeitos visuais |
| Arte técnica e arte de conceito |
| Scrum master, programação e desenho de níveis |
| Game design, história, música e programação |
| Desenho de som, programação e desenho de níveis |

## Riscos

Donos: [por decidir pelo grupo].

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Os níveis 2 e 3 ainda não têm desenho ([#45](https://github.com/P2D2627/P2D/issues/45), [#46](https://github.com/P2D2627/P2D/issues/46)) | Alta | Alto: o âmbito acordado são 2 a 3 níveis completos | O nível 1 deixou peças e regras reutilizáveis; cortar salas antes de cortar a qualidade |
| A alpha (21/12/2026) cai no mesmo dia de duas entregas de outras cadeiras | Alta | Médio | Fechar o conteúdo da alpha uma semana antes; a última semana só corrige |
| O jogo exportado comporta-se de forma diferente do editor: a vibração perdeu-se no export a 20/11; um caminho com as maiúsculas trocadas passa nos testes em Windows e parte no jogo exportado | Média | Alto: é o jogo exportado que os jogadores e o júri veem | Jogar cada build exportada antes de um evento; a conversão dos recursos para binário está desligada no repositório desde 22/11 |
| 15 dos 168 testes automáticos falhavam a 22/11 | Certa | Médio: um teste vermelho esconde uma regressão nova | Cada pull request mostra os mesmos casos a falhar e mais nenhum; corrigi-los é tarefa do sprint |
| A dificuldade afasta quem está fora do público-alvo | Média | Médio | O público é escolhido de propósito ([bloco 1](1_audience_and_market.md)); o atalho é a saída prevista, e os playtests medem onde se desiste ([bloco 8](8_playtesting_and_iteration.md)) |
| A câmara dá enjoo a parte dos jogadores | Média | Alto | Câmara fixa por defeito desde 22/11; teste de comparação planeado |
| Um inferno com sete pecados pode parecer batido aos docentes | Média | Alto | O pitch abre pelo julgamento escondido e pela oferta que chega quando se falha |
| Sem Git LFS, os ficheiros de arte pesam no repositório | Média | Baixo | Só os PNG exportados entram no repositório; os ficheiros de trabalho ficam numa pasta partilhada |

## Registo de protótipos

| Protótipo | Pergunta | Onde e como se testou | Decisão |
|---|---|---|---|
| Movimento da alma (11/11) | O movimento lê-se pesado e controlável? | No nível 1, pelo grupo e pelos docentes; os docentes jogaram melhor com o jogo todo a 0,75× | Corrida a 600 px/s, subida do salto em 0,45 s, queda rápida ([bloco 2](2_gameplay_and_rules.md)) |
| Crucifixo apontado com o rato (até 15/11) | Apontar o crucifixo com o rato ajuda? | O grupo, nas builds de teste: ninguém se adaptou | Sem rato; os poderes herdam o botão do crucifixo |
| Iluminação com luzes 2D (16 a 18/11) | Um nível escuro, em que só se vê o que está iluminado, lê-se e corre bem? | Uma cópia iluminada do nível 1, afinada a jogar em cerca de 20 sessões | Entra no jogo; o New Game abre o nível iluminado |
| Câmaras trocáveis (21/11) | Uma câmara fixa resolve as queixas da câmara que segue a alma? | Nasceu das queixas do piloto de 20/11; a troca com a tecla F10 foi testada pelo grupo a 21 e 22/11 | Câmara fixa por defeito desde 22/11; a comparação com jogadores está planeada ([bloco 8](8_playtesting_and_iteration.md)) |

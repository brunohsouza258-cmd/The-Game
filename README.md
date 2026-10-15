# Lanternas de Papel

**Um jogo de Bruno.** Créditos completos no menu (botão "Créditos") e ao fim de cada final; o texto fica em `data/credits.json`.

Visual novel de romance escolar e terror psicológico em Godot 4.3, no estilo de Doki Doki Literature Club. A navegação é por menu, e as cenas aparecem em tela cheia: cenário ilustrado, personagem centralizada e caixa de texto com efeito de digitação.

## Como abrir

1. Abra o Godot 4.3 (ou mais recente).
2. Importe esta pasta (`project.godot`).
3. Pressione Play (F5).

## Controles

- Mouse: todos os menus, escolhas e o poema.
- Enter / Espaço: completam a frase que está sendo digitada e depois avançam o texto.
- F5 / F9 (durante o jogo): salvar e carregar rápido no slot 1.
- Ctrl (segurar): pula o texto rapidamente, parando nas escolhas.
- **Avanço automático:** depois de um tempo o texto passa sozinho (botão "Auto" na caixa de diálogo; tempo ajustável em Configurações). Nunca avança sobre escolhas.

## Fluxo

1. **Título** (`scenes/main/Main.tscn`): as 4 garotas e os botões Novo Jogo, Continuar, Configurações e Sair. O Novo Jogo pede o nome do protagonista, e as garotas passam a chamá-lo por esse nome.
2. **Evento principal do dia** (`data/dialogue/main_dayN.json`): toca automaticamente ao começar cada dia. É a espinha dorsal linear da história, igual para todo mundo.
3. **Hub** (`scenes/main/Hub.tscn`): conversa com cada garota (uma vez por dia), um poema por dia, um passeio pela escola (cena extra com várias personagens, dias 2 a 11, `data/dialogue/extra_dayN.json`), avançar o dia, salvar/carregar, configurações e voltar ao título.
4. **Cena de diálogo** (`scenes/vn/VNScene.tscn`): a personagem fica centralizada e com a mesma altura para todas, com a base na borda inferior da tela e o cenário atrás.
5. **Poema** (`scenes/poem/PoemGame.tscn`), estilo Doki Doki: 5 de 18 palavras sorteadas (de um banco de 37). Cada palavra pontua as garotas a que combina e a bonequinha dela (topo do sprite) pula e mostra "+N ♥" quando ela gosta, e treme se não gosta. Cada uma tem barra de pontos e a líder ganha ★. Quem somar mais lê o poema e reage (afinidade/confiança); as outras com 6+ pontos também ganham +1 de afinidade.
6. **Final** (`scenes/ending/EndingScene.tscn`): 8 finais, depois da noite do festival (dia 12). Ao terminar, o jogo volta ao título.

## Sistemas

- **Pavor** (`GameState.dread`, 0–100): sobe com escolhas de investigação e desce com escolhas de conforto. Ele libera falas mais sombrias via `requires: {"dread": N}`.
- **Loop** (`GameSettings.loop_count`): conta quantas vezes o jogador começou a história. Fica salvo fora dos saves e não zera no Novo Jogo, então as personagens podem "lembrar" de partidas anteriores via `requires: {"loop": N}`.
- **Efeitos de diálogo**: `effects` funciona tanto nas escolhas quanto direto nas falas. `"effect": "glitch"` dispara o glitch visual e sonoro.
- **Saves**: 3 slots, mais save e load rápidos.
- **Configurações** (`user://settings.cfg`): volume geral, música e efeitos sonoros em canais de áudio separados, velocidade do texto e tela cheia.
- **Cenas com duas personagens:** as falas podem trazer `"side"` ("left"/"right") e `"partner"` (sprite da outra), e a que não fala fica escurecida ao fundo.
- **Transições:** cada troca de tela surge de um fade suave.
- **Histórico de falas**: botão "Histórico" durante o diálogo.

## Arte e áudio

- **Cenários** (`assets/backgrounds/`): 4 ilustrações geradas por IA e 5 derivadas delas por `tools/make_backgrounds.py` (festival à noite, escola à noite, escola decadente, telhado ao entardecer e telhado na chuva).
- **Personagens** (`assets/characters/`): PNGs com transparência real, todos recortados no mesmo enquadramento de busto. Maya e Hikari estão no estilo Classroom of the Elite. Yuna e Alice continuam no estilo anterior até haver créditos para gerar as duas no estilo novo.
- **Poses**: cada fala das garotas tem uma pose (`"pose"` no JSON): `neutral`, `happy`, `sad`, `surprised`, `scared`, `angry`, `thinking`, `close` ou `corrupted`. Hoje a pose é animada sobre o sprite base (pulo, tremor, aproximação, inclinação, cor e glitch). Se existir `assets/characters/<nome>_<pose>.png` (ex.: `yuna_sad.png`), o jogo usa essa imagem automaticamente naquela pose.
- **Trilha sonora** (`assets/music/`, créditos em `assets/music/CREDITS.md`): 7 faixas CC0 do OpenGameArt, com transição suave entre cenas (`scripts/audio/MusicPlayer.gd`). O glitch distorce o tom da música por um instante. Efeitos sonoros: `scripts/audio/SfxPlayer.gd`.

## Estado atual

- **A história está completa:** 12 dias em 3 atos, com um evento principal por dia, 4 conversas por dia (60 arquivos de diálogo) e 8 finais. Ao fim do dia 12, "Subir ao telhado às 21:40" leva ao final.
- O resumo completo da trama, das escolhas-chave e das condições de cada final está em `data/story_bible.md`.

## Ferramentas

- `python tools/make_backgrounds.py`: regenera os cenários derivados (requer Pillow).
- `python tools/validate_data.py`: valida os JSONs de diálogo e finais (referências `next`, nó `start`, backgrounds e sprites). Rode antes de cada commit.

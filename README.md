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
- Esc: menu de pausa (salvar/carregar, configurações, voltar ao hub ou ao título).
- H ou botão direito: esconde a caixa de texto para ver o cenário.
- **Avanço automático:** depois de um tempo o texto passa sozinho (botão "Auto" na caixa de diálogo; tempo ajustável em Configurações). Nunca avança sobre escolhas.

## Fluxo

1. **Título** (`scenes/main/Main.tscn`): as 4 garotas e os botões Novo Jogo, Continuar, Configurações e Sair. O Novo Jogo pede o nome do protagonista, e as garotas passam a chamá-lo por esse nome.
2. **Evento principal do dia** (`data/dialogue/main_dayN.json`): toca automaticamente ao começar cada dia. É a espinha dorsal linear da história, igual para todo mundo.
3. **Hub** (`scenes/main/Hub.tscn`): conversa com cada garota (uma vez por dia), um poema por dia, um passeio pela escola (cena extra com várias personagens, dias 2 a 12, `extra_dayN.json`), "ficar até mais tarde" (cena a sós com uma garota, dias 3, 5, 6, 8, 10 e 11, `late_dayN.json`), avançar o dia, salvar/carregar, configurações e voltar ao título.
4. **Cena de diálogo** (`scenes/vn/VNScene.tscn`): a personagem fica centralizada e com a mesma altura para todas, com a base na borda inferior da tela e o cenário atrás.
5. **Poema** (`scenes/poem/PoemGame.tscn`), estilo Doki Doki: 5 de 18 palavras sorteadas (de um banco de 37). Cada palavra pontua as garotas a que combina e a bonequinha dela (topo do sprite) pula e mostra "+N ♥" quando ela gosta, e treme se não gosta. Cada uma tem barra de pontos e a líder ganha ★. Quem somar mais lê o poema e reage (afinidade/confiança); as outras com 6+ pontos também ganham +1 de afinidade.
6. **Final** (`scenes/ending/EndingScene.tscn`): 8 finais, depois da noite do festival (dia 12). Cada um tem uma cena interativa curta (`data/dialogue/ending_<id>.json`) seguida do cartão final e dos créditos.

## Sistemas

- **Pavor** (`GameState.dread`, 0–100): sobe com escolhas de investigação e desce com escolhas de conforto. Ele libera falas mais sombrias via `requires: {"dread": N}`.
- **Loop** (`GameSettings.loop_count`): conta quantas vezes o jogador começou a história. Fica salvo fora dos saves e não zera no Novo Jogo, então as personagens podem "lembrar" de partidas anteriores via `requires: {"loop": N}`.
- **Efeitos de diálogo**: `effects` funciona tanto nas escolhas quanto direto nas falas. `"effect": "glitch"` dispara o glitch visual e sonoro.
- **Saves**: 3 slots, mais save e load rápidos.
- **Configurações** (`user://settings.cfg`): volume geral, música e efeitos sonoros em canais de áudio separados, velocidade do texto e tela cheia.
- **Efeitos de terror** (`scripts/effects/HorrorFX.gd`): o campo `"fx"` de um nó dispara `glitch` (tela rasgada), `static` (chuvisco), `flash_red`, `blackout`, `thud` ou `crash` (falsa queda do jogo, com janela de erro e terminal, no estilo Doki Doki; aceita `crash_lines`). Com pavor >= 60 a escola falha sozinha de vez em quando.
- **Ritmo e interface por fala:** `pace` (`slow`/`crawl`/`fast`/`instant`), `pause` (segundos antes do texto), `noauto` (não avança sozinho) e `corrupt` (segundos de texto embaralhado). Com pavor alto surgem batimentos cardíacos, a caixa treme e o nome da personagem falha.
- **Cenas com duas personagens:** as falas podem trazer `"side"` ("left"/"right") e `"partner"` (sprite da outra), e a que não fala fica escurecida ao fundo.
- **Transições:** cada troca de tela surge de um fade suave.
- **Histórico de falas**: botão "Histórico" durante o diálogo.

## Arte e áudio

- **Cenários** (`assets/backgrounds/`): 4 ilustrações geradas por IA e 5 derivadas delas por `tools/make_backgrounds.py` (festival à noite, escola à noite, escola decadente, telhado ao entardecer e telhado na chuva).
- **Personagens** (`assets/characters/`): PNGs com transparência real, todos recortados no mesmo enquadramento de busto. Maya e Hikari estão no estilo Classroom of the Elite. Yuna e Alice continuam no estilo anterior até haver créditos para gerar as duas no estilo novo.
- **Poses**: cada fala das garotas tem uma pose (`"pose"` no JSON): `neutral`, `happy`, `sad`, `surprised`, `scared`, `angry`, `thinking`, `close` ou `corrupted`. Hoje a pose é animada sobre o sprite base (pulo, tremor, aproximação, inclinação, cor e glitch). Se existir `assets/characters/<nome>_<pose>.png` (ex.: `yuna_sad.png`), o jogo usa essa imagem automaticamente naquela pose.
- **Trilha sonora** (`assets/music/`, créditos em `assets/music/CREDITS.md`): 10 faixas CC0 do OpenGameArt, com transição suave entre cenas (`scripts/audio/MusicPlayer.gd`). O glitch distorce o tom da música por um instante. Efeitos sonoros: `scripts/audio/SfxPlayer.gd`.

## Novidades de acessibilidade e extras

- **Aviso de saúde e bem-estar** sempre que o jogo abre, antes do título e da música (luzes e sons, conteúdo, pausas, contato do CVV 188 e o que o jogo faz com o nome de usuário). O botão de continuar libera após 4 s, e há atalho para ativar a redução de luzes e tremores (também em Configurações). Tamanho do texto ajustável.
- **Diário** do protagonista (`data/diary.json`): entradas que se desbloqueiam por dia, flags, confiança, pavor e loop.
- **Cenas de rota** (`route_<garota>_day9..12.json`): quem tem a maior afinidade (>= 8, sem empate) ganha um "momento a sós" por dia nos dias 9 a 12.
- **Eco do poema:** nos dias seguintes a garota que leu o poema cita a palavra que mais combinou com ela (`{poem_word}`, requisito `poem.<id>`).
- **Memória do loop:** a partir da 2ª partida, os eventos principais ganham um trecho extra (`"if": {"loop": 2}`).
- **Título que adoece** depois dos finais; **rosto que se quebra** (shader) com pavor alto; **ambiência** de chuva e efeitos de porta, sino e página.
- **Visual:** tema global (`assets/ui/theme.tres`) com botões arredondados e brilho no hover, título com contorno e sombra, lanternas de papel flutuando na tela inicial, botões que entram em fade e placa de nome na cor de cada personagem.
- **Saves com miniatura** e data. Controle: Start abre a pausa.
- Nós de diálogo aceitam `"if": {requisitos}` (só aparecem se atendidos), `"sfx"` e `"amb"`.

## Estado atual

- **A história está completa:** 12 dias em 3 atos, com um evento principal por dia, 4 conversas por dia (60 arquivos de diálogo) e 8 finais. Ao fim do dia 12, "Subir ao telhado às 21:40" leva ao final.
- O resumo completo da trama, das escolhas-chave e das condições de cada final está em `data/story_bible.md`.

## Ferramentas

- `Godot --headless --path . --script tools/simulate.gd`: joga a história inteira centenas de vezes com várias estratégias e imprime a distribuição de finais (para checar alcançabilidade e balanceamento).
- `Godot --headless --path . --script tools/smoke_test.gd`: toca todos os diálogos até o fim e abre as telas principais (sai com erro se algo falhar).
- `powershell -File tools/build_exe.ps1 -Godot <caminho do Godot.exe>`: gera `build/LanternasDePapel.exe` + `.pck` sem precisar dos export templates (o `.exe` é o Godot com o `.pck` de mesmo nome; mantenha os dois na mesma pasta). Para um `.exe` independente, instale os export templates e use o preset abaixo.
- `python tools/make_icon.py`: gera o ícone do jogo (`assets/icon.png` e `assets/icon.ico`). O ícone é embutido no `.exe` na exportação; para isso o Godot precisa do rcedit configurado em Editor > Configurações do editor > Export > Windows.
- `export_presets.cfg`: preset de exportação para Windows (precisa dos export templates do Godot). Exporte com `Godot --headless --path . --export-release "Windows Desktop" build/release/LanternasDePapel.exe`: gera um `.exe` único, sem o "(DEBUG)" no título.
- `python tools/make_backgrounds.py`: regenera os cenários derivados (requer Pillow).
- `python tools/validate_data.py`: valida os JSONs de diálogo e finais (referências `next`, nó `start`, backgrounds e sprites). Rode antes de cada commit.

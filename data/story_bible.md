# Lanternas de Papel — Bíblia da história (referência interna, não carregada pelo jogo)

Referência para manter a narrativa coerente ao expandir ou revisar o jogo.

## A verdade central

**Kaito Mori** era o melhor amigo de infância do protagonista. Os dois cresceram junto com a **Yuna**, que era vizinha do Kaito. O protagonista se mudou ainda criança e voltou para esta escola por causa de uma carta do Kaito ("Volta. A escola é chata sem você"). Kaito estava na turma da **Alice** (2-B) e corria a quarta raia do revezamento da **Hikari** (12s8, o melhor tempo do time).

Na noite do festival (dia 12), os dois subiram ao telhado para ver os fogos. Brigaram por uma besteira: o protagonista ter demorado tanto para voltar. Kaito subiu na grade para provocar ("Ainda sou mais corajoso que você"). Estava chovendo. Ele escorregou. O protagonista segurou a mão dele, a grade cortou a palma da mão do protagonista, e às **21:47** a mão ficou vazia. Foi um acidente. **Maya**, que gostava do Kaito e nunca disse, estava na escada e viu tudo.

Desde então, tudo volta ao dia 1 quando chega aquela noite. O loop é sustentado por duas pessoas que não conseguem soltar: o protagonista e a Maya. Cada volta apaga um pouco mais do Kaito e, depois, das pessoas em volta dele. Só a Maya retém as memórias.

**Regra de ouro:** nada de gore explícito. Violência implícita = consequências, ferimentos descobertos depois, ausências, texto perturbador.

## Estrutura

- Cada dia tem um **Evento Principal** (`main_dayN.json`) que toca automaticamente e é a espinha dorsal linear. As 4 garotas são opcionais, uma conversa por dia cada.
- **Pavor** (0–100) sobe ao investigar e desce ao buscar conforto. Ele escurece e avermelha os cenários (`VNScene.gd`) e libera falas via `requires: {"dread": N}`.
- **Loop** (`GameSettings.loop_count`) sobrevive entre partidas. Falas com `requires: {"loop": 2}` só aparecem a partir da 2ª partida.
- Também existe gate por flag: `requires: {"flags.x": 1}` (flag ligada) ou `0` (desligada).

## Linha do tempo

### Ato 1 — "Um ano normal" (Dias 1–4)
1. Chegada. Maya: "parece um nome que já falei muitas vezes". Alice: o relógio e o aluno esquecido. Hikari: o colega do time de quem esqueceu o nome.
2. O alto-falante: "{nome}, bem-vindo de volta. Dessa vez, tente—".
3. A carteira vazia com "K.M." e o primeiro flash do telhado. Maya pede a promessa de não subir. Yuna mostra a foto riscada. Alice e o anuário cortado. Hikari e a raia sem nome.
4. O caderno no armário, com a própria letra e datas futuras, e o nome Kaito Mori. Alice confirma o nome na lista de matrícula.

### Ato 2 — "Rachaduras" (Dias 5–8)
5. O festival é anunciado para o dia 12. O alto-falante chama o Kaito e depois diz que ele não existe. A voz dele: "Ainda sou mais corajoso que você". Alice formula a teoria e pode receber o caderno (flag `shared_notebook_alice`).
6. O protagonista acorda com os nós dos dedos em carne viva. "NÃO SUBA" riscado na parede com as unhas. Maya limpa a ferida. Hikari tem as mãos machucadas também.
7. A carteira some, o relógio para em 21:47 e a foto da turma mostra um rosto sobreposto. Maya repete a mesma frase três vezes. Yuna e as duas marmitas: ela pede ajuda (`yuna_asked_help`). O caderno da Alice fica em branco.
8. **Madrugada:** a porta do telhado se abre para a escola decadente, com os riscos de contagem e "VOCÊ SÓ NÃO CONSEGUIU SEGURAR". **Escolha-chave:** saber (`maya_truth_asked`) ou esquecer (`chose_forget`).

### Ato 3 — "O que resta" (Dias 9–12)
9. Quem escolheu saber ouve a revelação completa. Quem escolheu esquecer tem um "dia normal" que falha. Maya admite que também segura o loop. Yuna lembra do protagonista criança na foto.
10. Os alunos somem e o sol fica parado. **Escolha-chave:** salvar o Kaito (`try_save`), deixar ele ir (`accept_loss`) ou "não sei".
11. O dia perfeito demais ("não confia no dia bonito") e a risada do Kaito na escada. Alice entrega o relógio.
12. A noite do festival. Últimas conversas, depois "Subir ao telhado às 21:40" leva ao final.

## Finais (`EndingScene.gd`, nesta ordem de prioridade)
1. **Secreto:** 2ª partida + `maya_truth_asked` + `shared_notebook_alice` + `accept_loss` + pavor ≥ 60. Quebra a quarta parede: quem segura o loop é quem aperta "Novo Jogo".
2. **Verdade:** `accept_loss` + confiança da Maya ≥ 12 + pavor ≥ 50.
3. **Ilusão:** `chose_forget` ou pavor < 30. O loop recomeça.
4. **Rota (Maya/Yuna/Alice/Hikari):** maior afinidade ≥ 14 e confiança dessa garota ≥ 8.
5. **Recomeço:** todos os outros casos.

O simulador (5000 partidas aleatórias) confirma que os 8 finais são alcançáveis.

## Para expandir
- Mais cenas por dia (encontros no corredor, almoço, cenas extras por rota) são o caminho para aumentar a duração sem mexer na trama.
- Faltam cenários próprios para o telhado, a escola à noite e a escola decadente. Hoje eles são simulados com tint sobre os 4 cenários existentes.

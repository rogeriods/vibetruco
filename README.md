# Vibe Truco — Love2D

Jogo de Truco Paulista 1x1 (vs CPU ou vs amigo na rede local), feito em Love2D, retrato,
com visual na pegada do Balatro (fundo ondulante, cartas creme, manilha dourada, partículas).

Arquivos: `main.lua` (adapter fino) + `src/` (domínio, IA, rede, views) + `assets/`.

## Arquitetura (SOLID + boas práticas Lua)
- `src/config.lua` — constantes; `src/cards.lua` — regras puras do baralho, sem `love`.
- `src/game.lua` — máquina de estados (SRP: sem draw/IA; DIP: recebe `cards/config/fx` injetados).
- `src/ai.lua` — `Brain` puro (`chooseCard`, `shouldTrucar`, `decideResponse`); troque a dificuldade sem tocar no `Game` (OCP).
- `src/net/protocol.lua` — serializa mensagens (decode em ambiente vazio + pcall).
- `src/net/server.lua` — host autoritativo: roda as regras, valida intenções, envia snapshots.
- `src/net/client.lua` — convidado: manda intenções, espelha snapshots.
- `src/net/ip.lua` — descobre o IPv4 local (desktop) pra mostrar ao amigo.
- `src/views/seat_view.lua` — view model "mine/them"; as views não sabem se é CPU ou humano.
- `src/views/lobby_view.lua` — menu, criar sala e entrar por IP.
- `src/views/table_view.lua` — só desenho, cada seção em função pequena; devolve hitboxes.
- `src/app.lua` — compõe tudo e controla os modos `menu/solo/host/client`.
- Locais em vez de globais, timers no `Game`, hitboxes devolvidas pela view.

## Jogar em rede local (LAN, 1v1)
1. Os dois aparelhos precisam estar **na mesma rede Wi-Fi/roteador**.
2. Host: `CRIAR SALA (LAN)` → a tela mostra o IP (ex: `192.168.0.98`) e a porta `6789`.
3. Convidado: `ENTRAR EM SALA` → digita o IP do host → `CONECTAR`.
4. Primeiro a conectar entra; o host começa. `Esc`/voltar sai da partida.

Detalhes técnicos:
- ENet (UDP confiável) já vem embutido no LÖVE: `require("enet")`, porta **UDP 6789**.
- O host é autoritativo: o convidado nunca calcula regra, só envia `play/truco/respond/next`.
- Snapshots a 10 Hz; a mão do host é enviada como cartas ocultas ao convidado (anti-cheat básico).
- No Windows, o firewall pode pedir permissão na primeira vez que criar sala — **permitir em rede privada**.
- Em Android, a detecção automática do IP pode falhar: veja o IP em `Configurações > Wi-Fi`.

Teste automatizado de rede (host + cliente no loopback):
```
love . --test-net
```
O resultado sai no console e em `net_test_out.txt`.

## Gerar build Windows para enviar a um amigo
```
powershell -ExecutionPolicy Bypass -File .\build.ps1
```
Saídas em `dist/`:
- `VibeTruco.exe` — LÖVE fusionado com o jogo (precisa das DLLs ao lado).
- `VibeTruco-Windows.zip` — **este é o arquivo para enviar** (exe + DLLs + LEIA-ME).
- `LEIA-ME.txt` — instruções de execução, SmartScreen e LAN.

O script copia um `.love` só com `main.lua`, `conf.lua`, `src/` e `assets/`
(fica de fora a versão web, testes e docs). Requer LÖVE instalado em
`C:\Program Files\LOVE` (ou passe `-LoveDir`).

## Regras implementadas
- Baralho de 40 (sem 8/9/10), manilha = vira + 1
- Força manilhas: ouros < espadas < copas < paus (4 de paus = zap)
- Ordem normal: 3 > 2 > A > K > J > Q > 7 > 6 > 5 > 4
- Melhor de 3 vazas. Vaza 1 empatada: quem ganhar a 2ª leva. Tudo melado = sem pontos.
- Truco > Seis > Nove > Doze. Correu = adversário leva o valor atual.
- Mão de 11 vale 3 direto, sem truco. Primeiro aos 12 vence.

## Rodar no PC
1. Instale o Love2D 11.5: https://love2d.org
2. Arraste a pasta `vibetruco/` pra cima do `love.exe`
3. Mouse funciona como toque. Teclas: `1/2/3` joga carta, `T` pede truco, `Enter` avança modal.

## Rodar no celular (Android)
Opção fácil:
1. Instale o app **Love2D for Android** (itch.io / Play).
2. Compacte a pasta inteira (`main.lua`, `conf.lua`, `src/`, `assets/`) num zip e renomeie pra `truco.love`.
3. Copie pro celular e abra com o app Love2D.

## Layout mobile
- Base virtual 540x960 com letterbox + escala automática (`conf.lua` já seta retrato, highdpi, touch).
- Botões com 68px de altura virtual (~área de dedo), cartas da mão com hitbox estendida.
- Sem dependências, roda a 60fps em aparelho fraco.

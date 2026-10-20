-- tests/net_smoke.lua — teste de fumaça da rede (host + cliente no loopback).
-- Rode: love . --test-net   (resultado em net_test_out.txt)
local Config = require("src.config")
local Cards = require("src.cards")
local Game = require("src.game")
local Server = require("src.net.server")
local Client = require("src.net.client")
local NetIP = require("src.net.ip")
local SeatView = require("src.views.seat_view")

local M = {}
local hostGame, clientGame, server, client
local lines, done, failed, elapsed, step, stepT

local function noopFx()
  return { toast = function() end, burst = function() end, shake = function() end }
end

local function log(s)
  lines[#lines + 1] = s
  print(s)
end

local function finish(ok, msg)
  failed = not ok
  if msg then log(msg) end
  log(ok and "RESULT: PASS" or "RESULT: FAIL")
  local f = io.open("net_test_out.txt", "w")
  if f then f:write(table.concat(lines, "\n") .. "\n"); f:close() end
  done = true
end

function M.start()
  lines, done, failed, elapsed, step, stepT = {}, false, false, 0, 0, 0
  log("IP local detectado: " .. tostring(NetIP.localIPv4()))
  hostGame = Game.new({ cards = Cards, config = Config, fx = noopFx() })
  clientGame = Game.new({ cards = Cards, config = Config, fx = noopFx() })
  server = Server.new(hostGame, 6799, Config)
  if not server then return finish(false, "server nao subiu (porta ocupada?)") end
  client = Client.new("127.0.0.1", 6799, clientGame)
  if not client then return finish(false, "client nao criou") end
  log("conectando...")
end

local function nextStep()
  step = step + 1
  stepT = 0
end

function M.update(dt)
  if done then
    elapsed = elapsed + dt
    if elapsed > 1.0 then love.event.quit() end
    return
  end
  elapsed = elapsed + dt
  if elapsed > 20 then return finish(false, "timeout geral") end

  server:update(dt)
  client:update(dt)
  stepT = stepT + dt

  if step == 0 then
    if client.failed then return finish(false, client.reason or "cliente falhou") end
    if client.ready and stepT > 0.4 then
      log("cliente conectado (seat " .. tostring(client.seat) .. ")")
      if #(clientGame.cpuHand or {}) ~= 3 then return finish(false, "mao do cliente nao chegou: " .. #(clientGame.cpuHand or {})) end
      if #(clientGame.youHand or {}) ~= 3 then return finish(false, "mao oculta do oponente nao chegou") end
      if clientGame.youHand[1].rank ~= "?" then return finish(false, "mao do host vazou para o cliente") end
      if not clientGame.vira then return finish(false, "vira nao sincronizou") end
      log("snapshot inicial ok (mao do host oculta)")
      nextStep()
    end

  elseif step == 1 then
    if stepT > 0.2 then
      if hostGame.vez == "you" then
        local ok = hostGame:play("you", 1)
        log("host jogou carta 1: " .. tostring(ok))
        if not ok then return finish(false, "host nao conseguiu jogar") end
      end
      nextStep()
    end

  elseif step == 2 then
    if stepT > 0.4 then
      if not clientGame.mesaYou then return finish(false, "cliente nao viu a carta do host") end
      log("cliente viu a carta do host")
      -- Regressao: com apenas a carta do host na mesa, a area do oponente
      -- no host precisa ficar vazia (bug do "and/or" com nil duplicava a carta).
      local hostVm = SeatView.build(hostGame, "you", Config)
      if hostVm.myMesa ~= hostGame.mesaYou then return finish(false, "host myMesa nao aponta para mesaYou") end
      if hostVm.oppMesa ~= nil then return finish(false, "host oppMesa deveria ser nil antes do cliente jogar") end
      local clientVm = SeatView.build(clientGame, "cpu", Config)
      if clientVm.myMesa ~= nil then return finish(false, "cliente myMesa deveria ser nil antes de jogar") end
      if clientVm.oppMesa ~= clientGame.mesaYou then return finish(false, "cliente oppMesa nao aponta para mesaYou") end
      log("view model ok (mesa do oponente vazia no host)")
      if clientGame.vez ~= "cpu" then return finish(false, "turno nao chegou ao cliente (vez=" .. tostring(clientGame.vez) .. ")") end
      local sent = client:send({ t = "play", i = 1 })
      log("cliente enviou jogada: " .. tostring(sent))
      if not sent then return finish(false, "send falhou") end
      nextStep()
    end

  elseif step == 3 then
    if stepT > 0.5 then
      if not hostGame.mesaCpu then return finish(false, "host nao recebeu a jogada do cliente") end
      log("host recebeu a jogada do cliente")
      if #(hostGame.cpuHand or {}) ~= 2 then return finish(false, "mao do cliente no host nao diminuiu") end
      local hostVm = SeatView.build(hostGame, "you", Config)
      if hostVm.myMesa ~= hostGame.mesaYou then return finish(false, "host myMesa nao aponta para mesaYou") end
      if hostVm.oppMesa ~= hostGame.mesaCpu then return finish(false, "host oppMesa nao aponta para mesaCpu") end
      if hostVm.myMesa.id == hostVm.oppMesa.id then return finish(false, "host desenha a mesma carta nas duas areas") end
      log("view model ok (duas cartas distintas no host)")
      return finish(true, "sincronizacao host<->cliente ok")
    end
  end
end

function M.draw()
  love.graphics.clear(0.05, 0.1, 0.08)
  love.graphics.setColor(1, 1, 1)
  local y = 20
  love.graphics.print("NET SMOKE TEST - " .. (done and (failed and "FAIL" or "PASS") or "rodando"), 20, y)
  y = y + 30
  for _, l in ipairs(lines) do
    love.graphics.print(l, 20, y)
    y = y + 20
  end
end

return M

-- src/game.lua — máquina de estados do Truco (domínio puro + timers).
-- SOLID:
--   SRP: só regras/transições (sem draw, som ou IA).
--   DIP: recebe {cards, config, rng, fx} por injeção; emite efeitos via fx (sem acoplar view).
local Game = {}
Game.__index = Game

function Game.new(deps)
  local self = setmetatable({}, Game)
  self.cards, self.cfg = deps.cards, deps.config
  self.rng = deps.rng or math.random
  self.fx = deps.fx
  self:resetMatch()
  return self
end

function Game:resetMatch()
  self.scoreYou, self.scoreCpu = 0, 0
  self.maoNum = 1
  self:newMao()
end

function Game:newMao()
  local C = self.cards
  if self.scoreYou >= self.cfg.MAX_SCORE or self.scoreCpu >= self.cfg.MAX_SCORE then
    self.phase, self.winner = "gameOver", (self.scoreYou >= self.cfg.MAX_SCORE) and "you" or "cpu"
    return
  end
  local deck = C.newDeck(self.cfg.RANKS, self.cfg.SUITS)
  C.shuffle(deck, function(a, b) return love.math.random(a, b) end)
  self.youHand = { table.remove(deck), table.remove(deck), table.remove(deck) }
  self.cpuHand = { table.remove(deck), table.remove(deck), table.remove(deck) }
  self.vira = table.remove(deck)
  self.manilha = C.nextRank(self.cfg.RANKS, self.vira.rank)
  self.mesaYou, self.mesaCpu = nil, nil
  self.vazaNum, self.playedThisVaza = 1, 0
  self.vazaRes = {}
  self.pendingTruco, self.lastTrucoBy, self.roundWinner = nil, nil, nil
  self.phase = "play"
  self.maoDe11 = (self.scoreYou == 11 or self.scoreCpu == 11)
  self.valendo = self.maoDe11 and 3 or 1
  self.leader = (self.maoNum % 2 == 1) and "you" or "cpu"
  self.vez = self.leader
  self.cpuTimer = (self.vez == "cpu") and 1.0 or 0
  self.resolveTimer = -1
  if self.fx then
    self.fx:toast(self.maoDe11 and "MAO DE ONZE! Valendo 3, sem truco."
      or ("Mao " .. self.maoNum .. " - " .. (self.vez == "you" and "voce comeca!" or "CPU comeca.")), 2.2)
  end
end

function Game:power(card) return self.cards.power(card, self.manilha, self.cfg.RANK_POWER, self.cfg.SUIT_POWER) end

function Game:winnerSoFar()
  local y, c = 0, 0
  for _, r in ipairs(self.vazaRes) do
    if r == "you" then y = y + 1 elseif r == "cpu" then c = c + 1 end
  end
  if y >= 2 then return "you" end
  if c >= 2 then return "cpu" end
  if #self.vazaRes == 1 and self.vazaRes[1] == "tie" then return nil end
  if #self.vazaRes >= 2 then
    if self.vazaRes[1] == "tie" then
      if self.vazaRes[2] == "you" then return "you" end
      if self.vazaRes[2] == "cpu" then return "cpu" end
    end
  end
  return nil
end

function Game:_finish(winner)
  local colors = self.cfg.COLORS
  if winner == "you" then self.scoreYou = math.min(self.cfg.MAX_SCORE, self.scoreYou + self.valendo)
  elseif winner == "cpu" then self.scoreCpu = math.min(self.cfg.MAX_SCORE, self.scoreCpu + self.valendo) end
  self.phase, self.roundWinner = "roundEnd", winner
  self.maoNum = self.maoNum + 1
  if self.fx then
    if winner == "you" then self.fx:burst(270, 430, colors.yellow, 40)
    elseif winner == "cpu" then self.fx:burst(270, 300, colors.red, 40) end
  end
  if self.scoreYou >= self.cfg.MAX_SCORE or self.scoreCpu >= self.cfg.MAX_SCORE then
    self.phase, self.winner = "gameOver", (self.scoreYou >= self.cfg.MAX_SCORE) and "you" or "cpu"
  end
end

function Game:resolveVaza()
  local res = "tie"
  if self:power(self.mesaYou) > self:power(self.mesaCpu) then res = "you"
  elseif self:power(self.mesaCpu) > self:power(self.mesaYou) then res = "cpu" end
  self.vazaRes[#self.vazaRes + 1] = res
  if self.fx then
    local colors = self.cfg.COLORS
    self.fx:toast(res == "you" and ("Voce levou a vaza " .. self.vazaNum .. "!")
      or res == "cpu" and ("CPU levou a vaza " .. self.vazaNum .. ".")
      or ("Vaza " .. self.vazaNum .. " empatou."), 1.6)
    if res == "you" then self.fx:burst(270, 480, colors.green, 26)
    elseif res == "cpu" then self.fx:burst(270, 320, colors.red, 26) end
  end
  local early = self:winnerSoFar()
  if early then self:_finish(early); return end
  if #self.vazaRes >= 3 then
    local y, c = 0, 0
    for _, r in ipairs(self.vazaRes) do
      if r == "you" then y = y + 1 elseif r == "cpu" then c = c + 1 end
    end
    if y ~= c then self:_finish(y > c and "you" or "cpu")
    else
      self.phase, self.roundWinner = "roundEnd", nil
      self.maoNum = self.maoNum + 1
      if self.fx then self.fx:toast("Mao melada! Ninguem pontua.", 2.0) end
    end
    return
  end
  if res ~= "tie" then self.leader = res end
  self.mesaYou, self.mesaCpu = nil, nil
  self.vazaNum = self.vazaNum + 1
  self.playedThisVaza = 0
  self.vez = self.leader
  if self.vez == "cpu" then self.cpuTimer = 0.9 end
end

-- Ação do turno. Retorna ok, erro.
function Game:play(who, idx)
  if self.phase ~= "play" then return false, "not-play" end
  if self.vez ~= who then if self.fx then self.fx:toast("Aguarde sua vez!", 1.0) end; return false, "turn" end
  local hand = (who == "you") and self.youHand or self.cpuHand
  if not hand[idx] then return false, "empty" end
  if who == "you" then self.mesaYou = table.remove(hand, idx)
  else self.mesaCpu = table.remove(hand, idx) end
  self.playedThisVaza = self.playedThisVaza + 1
  if self.fx then self.fx:burst(270, who == "you" and 480 or 320, self.cfg.COLORS.cream, 10) end
  if self.playedThisVaza >= 2 then
    self.resolveTimer = 1.0
  else
    self.vez = (who == "you") and "cpu" or "you"
    if self.vez == "cpu" then self.cpuTimer = 0.8 end
  end
  return true
end

function Game:nextTruco() return self.cfg.nextTruco(self.valendo) end
function Game:canTruco() return self.phase == "play" and not self.maoDe11 and self:nextTruco() ~= nil end

-- Ações com guarda de fase: evitam avanço duplo (host + cliente clicando "próxima mão").
function Game:nextMao()
  if self.phase ~= "roundEnd" then return false end
  self:newMao()
  return true
end

function Game:rematch()
  if self.phase ~= "gameOver" then return false end
  self:resetMatch()
  return true
end

function Game:requestTruco(by)
  if self.phase ~= "play" then return false end
  if self.maoDe11 then if self.fx then self.fx:toast("Mao de 11: nao pode trucar!", 1.6) end; return false end
  if self.pendingTruco then return false end
  local nv = self:nextTruco()
  if not nv then if self.fx then self.fx:toast("Ja ta valendo 12!", 1.4) end; return false end
  if self.lastTrucoBy == by and self.valendo > 1 then
    if self.fx then self.fx:toast("Voce ja pediu! Aguarde.", 1.4) end; return false
  end
  self.pendingTruco = { by = by, value = nv }
  if self.fx then
    self.fx:shake(0.35)
    self.fx:toast(by == "you" and ("Voce pediu " .. self.cfg.trucoLabel(nv) .. "!...")
      or ("CPU pediu " .. self.cfg.trucoLabel(nv) .. "!"), 1.5)
  end
  self.phase = (by == "you") and "cpuThinking" or "youDecision"
  if by == "you" then self.cpuTimer = 1.1 end
  return true
end

function Game:resolveTruco(accepted, raised)
  local p = self.pendingTruco
  if not p then return end
  if raised then
    self.valendo = p.value
    self.lastTrucoBy = p.by
    local newBy = (p.by == "you") and "cpu" or "you"
    self.pendingTruco = { by = newBy, value = self.cfg.nextTruco(p.value) }
    self.phase = (newBy == "you") and "cpuThinking" or "youDecision"
    if newBy == "you" then self.cpuTimer = 1.1 end
    if self.fx then self.fx:shake(0.4); self.fx:toast(self.cfg.trucoLabel(self.pendingTruco.value) .. "!!!", 1.4) end
    return
  end
  if accepted then
    self.valendo, self.lastTrucoBy, self.pendingTruco = p.value, p.by, nil
    self.phase = "play"
    if self.fx then self.fx:toast("Aceitou! Valendo " .. self.valendo .. "!", 1.6) end
  else
    local winner = p.by
    self.pendingTruco = nil
    self:_finish(winner)
    if self.fx then self.fx:toast((winner == "you" and "CPU correu! +" or "Voce correu! CPU +") .. self.valendo .. " pts", 2.0) end
  end
end

function Game:forfeit(who)
  if self.phase ~= "play" then return end
  self:_finish(who == "you" and "cpu" or "you")
  if self.fx then
    self.fx:toast(who == "you" and ("Voce correu! +" .. self.valendo .. " p/ oponente")
      or ("Oponente correu! +" .. self.valendo .. " p/ voce"), 2.0)
  end
end

-- ============ NETWORK SNAPSHOT ============
-- Contrato serializável: apenas dados (sem métodos, sem timers).
local SNAPSHOT_FIELDS = {
  "scoreYou", "scoreCpu", "maoNum", "vez", "leader", "vazaNum", "valendo",
  "manilha", "vira", "youHand", "cpuHand", "mesaYou", "mesaCpu", "vazaRes",
  "phase", "pendingTruco", "maoDe11", "winner", "roundWinner", "playedThisVaza",
  "lastTrucoBy",
}

function Game:snapshot()
  local s = {}
  for _, k in ipairs(SNAPSHOT_FIELDS) do s[k] = self[k] end
  return s
end

function Game:restore(s)
  if type(s) ~= "table" then return end
  for _, k in ipairs(SNAPSHOT_FIELDS) do self[k] = s[k] end
  self.cpuTimer, self.resolveTimer = 0, -1
end

return Game

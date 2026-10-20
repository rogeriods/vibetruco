-- src/ai.lua — cérebro da CPU (OCP: troque por outra dificuldade sem tocar no Game).
-- Funções puras sobre o estado: recebem game + rand, devolvem decisão.
local Brain = {}

local function sortedByPower(game)
  local ord = {}
  for i, c in ipairs(game.cpuHand) do
    ord[#ord + 1] = { i = i, p = game:power(c) }
  end
  table.sort(ord, function(a, b) return a.p < b.p end)
  return ord
end

function Brain.chooseCard(game)
  if #game.cpuHand == 0 then return 1 end
  local ord = sortedByPower(game)
  if game.mesaYou then
    local need = game:power(game.mesaYou)
    for _, o in ipairs(ord) do if o.p > need then return o.i end end
    return ord[1].i
  end
  if #game.vazaRes == 0 and game.cards.countManilhas(game.cpuHand, game.manilha) > 0 then
    for _, o in ipairs(ord) do if o.p > 100 then return o.i end end
  end
  return ord[math.min(#ord, 2)].i
end

function Brain.shouldTrucar(game, rand)
  rand = rand or math.random
  if not game:canTruco() or game.pendingTruco or #game.cpuHand == 0 then return false end
  local s = game.cards.handStrength(game.cpuHand, game.manilha, game.cfg.RANK_POWER, game.cfg.SUIT_POWER)
  local m = game.cards.countManilhas(game.cpuHand, game.manilha)
  if #game.vazaRes == 0 and #game.cpuHand == 3 then
    if m >= 2 then return rand() < 0.65 end
    if s > 120 then return rand() < 0.35 end
    return rand() < 0.06
  end
  if #game.vazaRes == 1 and game.vazaRes[1] == "cpu" and s > 20 then return rand() < 0.30 end
  return rand() < 0.04
end

-- Retorna {accept=bool, raise=bool}
function Brain.decideResponse(game, rand)
  rand = rand or math.random
  local p = game.pendingTruco
  local s = game.cards.handStrength(game.cpuHand, game.manilha, game.cfg.RANK_POWER, game.cfg.SUIT_POWER)
  local m = game.cards.countManilhas(game.cpuHand, game.manilha)
  local strong = (m >= 1 and s > 60) or s > 130 or m >= 2
  local veryStrong = m >= 2 or s > 200
  if p.value >= 9 and not veryStrong then return { accept = false } end
  if strong then
    if veryStrong and p.value < 12 and rand() < 0.35 then return { accept = true, raise = true } end
    return { accept = true }
  end
  if rand() < 0.45 then return { accept = true } end
  return { accept = false }
end

return Brain

-- src/views/seat_view.lua — adaptador de perspectiva (view model).
-- As views não conhecem "you/cpu": trabalham com "mine/them", seja solo ou LAN.
local SeatView = {}

function SeatView.build(game, seat, cfg, opts)
  opts = opts or {}
  local isYou = seat == "you"
  -- Cuidado: "isYou and a or b" quebra quando a == nil (cai no b).
  -- Mesa/hand podem ser nil, então seleciona com if explícito.
  local function sel(a, b)
    if isYou then return a end
    return b
  end
  local function mapRes(r)
    if r == "tie" then return "tie" end
    return (r == seat) and "mine" or "them"
  end

  local vaza = {}
  for i, r in ipairs(game.vazaRes or {}) do vaza[i] = mapRes(r) end

  local phase
  if game.phase == "youDecision" or game.phase == "cpuThinking" then
    local responder = (game.phase == "youDecision") and "you" or "cpu"
    phase = (responder == seat) and "myResponse" or "theirResponse"
  else
    phase = game.phase
  end

  local pending = nil
  if game.pendingTruco then
    pending = { value = game.pendingTruco.value, byMine = (game.pendingTruco.by == seat) }
  end

  local vm = {
    myScore = sel(game.scoreYou, game.scoreCpu),
    oppScore = sel(game.scoreCpu, game.scoreYou),
    myLabel = "", -- Geralmente fica a label VOCE, mas eu removi para o VS ficar melhor na tela
    oppLabel = opts.oppLabel or "CPU",
    myHand = sel(game.youHand, game.cpuHand) or {},
    oppHand = sel(game.cpuHand, game.youHand) or {},
    myMesa = sel(game.mesaYou, game.mesaCpu),
    oppMesa = sel(game.mesaCpu, game.mesaYou),
    vazaRes = vaza,
    phase = phase,
    myTurn = (game.vez == seat),
    maoNum = game.maoNum or 1,
    vazaNum = game.vazaNum or 1,
    maoDe11 = game.maoDe11 == true,
    valendo = game.valendo or 1,
    manilha = game.manilha or "-",
    vira = game.vira,
    pendingTruco = pending,
    nextTruco = cfg.nextTruco(game.valendo),
    roundWinner = game.roundWinner and mapRes(game.roundWinner) or nil,
    winner = game.winner and mapRes(game.winner) or nil,
    net = opts.net == true,
  }
  vm.canTruco = phase == "play" and vm.myTurn and not vm.maoDe11
    and vm.nextTruco ~= nil and pending == nil
  return vm
end

return SeatView

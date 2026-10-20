-- src/views/table_view.lua — compõe a mesa a partir do view model (vm).
-- Não conhece regras nem rede: só desenha "minhas" e "do oponente".
local UI = require("src.ui")

local TableView = {}
TableView.__index = TableView

function TableView.new(deps)
  return setmetatable({ cfg = deps.config, fonts = deps.fonts, cards = deps.cardsView }, TableView)
end

function TableView:layout()
  local VW = self.cfg.VW
  local L = { handCards = {} }
  local cw, ch, gap = 138, 196, 14
  local sx = (VW - (3 * cw + 2 * gap)) / 2
  for i = 1, 3 do L.handCards[i] = { x = sx + (i - 1) * (cw + gap), y = 726, w = cw, h = ch, tilt = (i - 2) * 7 } end
  L.mesaYou = { x = VW / 2 - 85, y = 440, w = 170, h = 200 }
  L.mesaCpu = { x = VW / 2 - 85, y = 218, w = 170, h = 200 }
  L.vira = { x = 36, y = 140, w = 76, h = 108 }
  return L
end

function TableView:background(time)
  local VW, VH, colors = self.cfg.VW, self.cfg.VH, self.cfg.COLORS
  love.graphics.setColor(colors.bg0); love.graphics.rectangle("fill", 0, 0, VW, VH)
  love.graphics.setColor(colors.bg1); love.graphics.rectangle("fill", 0, 0, VW, VH)
  for i = 1, 6 do
    local yy = ((time * 40 + i * 170) % (VH + 240)) - 120
    love.graphics.setColor(0.05, 0.30, 0.20, 0.35)
    love.graphics.ellipse("fill", VW / 2 + math.sin(time * 0.7 + i) * 60, yy, 320, 46, 64)
  end
  love.graphics.setColor(colors.bgSwirl)
  for i = 1, 5 do
    local yy = ((time * 22 + i * 230) % (VH + 240)) - 120
    love.graphics.ellipse("fill", VW / 2 - math.sin(time * 0.5 + i * 2) * 80, yy, 220, 30, 48)
  end
  love.graphics.setColor(0, 0, 0, 0.25); love.graphics.rectangle("fill", 0, VH - 220, VW, 220)
end

function TableView:hud(vm)
  local VW, colors, f = self.cfg.VW, self.cfg.COLORS, self.fonts
  UI.shadow(16, 14, 150, 66, 14)
  love.graphics.setColor(0.10, 0.55, 0.30); UI.rr("fill", 16, 14, 150, 66, 14)
  love.graphics.setColor(1, 1, 1); love.graphics.setFont(f.tiny); love.graphics.print(vm.myLabel, 28, 20)
  love.graphics.setFont(f.big); love.graphics.print(tostring(vm.myScore), 28, 34)
  UI.shadow(VW - 166, 14, 150, 66, 14)
  love.graphics.setColor(0.75, 0.18, 0.22); UI.rr("fill", VW - 166, 14, 150, 66, 14)
  love.graphics.setColor(1, 1, 1); love.graphics.setFont(f.tiny)
  love.graphics.print(vm.oppLabel, VW - 28 - f.tiny:getWidth(vm.oppLabel), 20)
  love.graphics.setFont(f.big)
  love.graphics.print(tostring(vm.oppScore), VW - 28 - f.big:getWidth(tostring(vm.oppScore)), 34)

  local vv = "VALENDO " .. vm.valendo
  love.graphics.setFont(f.med)
  local vww = f.med:getWidth(vv) + 34
  UI.shadow(VW / 2 - vww / 2, 22, vww, 38, 19)
  love.graphics.setColor(colors.yellow); UI.rr("fill", VW / 2 - vww / 2, 22, vww, 38, 19)
  love.graphics.setColor(colors.ink); love.graphics.print(vv, VW / 2 - f.med:getWidth(vv) / 2, 31)
  love.graphics.setColor(1, 1, 1, 0.9); love.graphics.setFont(f.small)
  local sub = "Mao " .. vm.maoNum .. " - Vaza " .. math.min(vm.vazaNum, 3)
    .. (vm.maoDe11 and " - MAO DE 11" or "") .. (vm.net and " - LAN" or "")
  love.graphics.print(sub, VW / 2 - f.small:getWidth(sub) / 2, 64)
end

function TableView:mid(vm, L, time)
  local VW, colors, f = self.cfg.VW, self.cfg.COLORS, self.fonts
  love.graphics.setColor(0, 0, 0, 0.35); UI.rr("fill", 16, 122, VW - 32, 78, 14)
  love.graphics.setColor(1, 1, 1, 0.85); love.graphics.setFont(f.tiny); love.graphics.print("VIRA", 40, 128)
  if vm.vira then
    self.cards:face(vm.vira, vm.manilha, L.vira.x, L.vira.y - 8, L.vira.w, L.vira.h, { tilt = -8 }, time)
  end
  love.graphics.setFont(f.small); love.graphics.setColor(colors.yellow)
  love.graphics.print("Manilha: " .. vm.manilha, 124, 140)
  love.graphics.setColor(1, 1, 1, 0.8); love.graphics.setFont(f.tiny)
  love.graphics.print("ordem: 4 5 6 7 Q J K A 2 3", 124, 162)
  for i = 1, #vm.oppHand do self.cards:back(360 + (i - 1) * 46, 126, 58, 66, (i - 2) * 6) end
  local s = "Vazas "
  for i = 1, 3 do
    local r = vm.vazaRes[i]
    s = s .. (r == "mine" and "X " or r == "them" and "O " or "- ")
  end
  love.graphics.setColor(1, 1, 1, 0.9); love.graphics.setFont(f.small); love.graphics.print(s, 124, 182)
end

function TableView:mesa(vm, L, time)
  local VW, colors, f = self.cfg.VW, self.cfg.COLORS, self.fonts
  love.graphics.setColor(1, 1, 1, 0.25); love.graphics.setLineWidth(2)
  UI.rr("line", L.mesaCpu.x - 10, L.mesaCpu.y - 24, L.mesaCpu.w + 20, L.mesaCpu.h + 34, 16)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 0.5); love.graphics.setFont(f.tiny)
  love.graphics.print(vm.oppLabel, VW / 2 - f.tiny:getWidth(vm.oppLabel) / 2, L.mesaCpu.y - 20)
  if vm.oppMesa then
    self.cards:face(vm.oppMesa, vm.manilha, L.mesaCpu.x, L.mesaCpu.y, L.mesaCpu.w, L.mesaCpu.h, { tilt = 3 }, time)
  else
    love.graphics.setColor(1, 1, 1, 0.18); love.graphics.setFont(f.med); love.graphics.print("?", VW / 2 - 8, L.mesaCpu.y + 80)
  end
  love.graphics.setColor(colors.yellow); love.graphics.setFont(f.big); love.graphics.print("VS", VW / 2 - 18, 424)
  love.graphics.setColor(1, 1, 1, 0.25); love.graphics.setLineWidth(2)
  UI.rr("line", L.mesaYou.x - 10, L.mesaYou.y - 8, L.mesaYou.w + 20, L.mesaYou.h + 34, 16)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 0.5); love.graphics.setFont(f.tiny)
  love.graphics.print(vm.myLabel, VW / 2 - f.tiny:getWidth(vm.myLabel) / 2, L.mesaYou.y - 4)
  if vm.myMesa then
    self.cards:face(vm.myMesa, vm.manilha, L.mesaYou.x, L.mesaYou.y, L.mesaYou.w, L.mesaYou.h, { tilt = -3 }, time)
  end
end

function TableView:hand(vm, fx, L, time)
  local VW, f = self.cfg.VW, self.fonts
  local hint = ""
  if vm.phase == "play" then
    hint = vm.myTurn and "TOQUE NUMA CARTA PRA JOGAR" or (vm.oppLabel .. " jogando...")
  elseif vm.phase == "theirResponse" then
    hint = "aguardando " .. vm.oppLabel
  end
  love.graphics.setColor(1, 1, 1, 0.85); love.graphics.setFont(f.tiny)
  if hint ~= "" then love.graphics.print(hint, VW / 2 - f.tiny:getWidth(hint) / 2, 704) end
  for i, c in ipairs(vm.myHand) do
    local s = L.handCards[i]
    if s then
      local bob = math.sin(time * 2.2 + i * 1.7) * 4
      local sel = (vm.phase == "play" and vm.myTurn)
      self.cards:face(c, vm.manilha, s.x, s.y + bob + (sel and -6 or 6), s.w, s.h,
        { tilt = s.tilt, selected = sel }, time)
    end
  end
  if fx.toastT > 0 then
    love.graphics.setFont(f.small)
    local tw = f.small:getWidth(fx.toastText) + 28
    UI.shadow(VW / 2 - tw / 2, 668, tw, 34, 17)
    love.graphics.setColor(self.cfg.COLORS.dark); UI.rr("fill", VW / 2 - tw / 2, 668, tw, 34, 17)
    love.graphics.setColor(1, 1, 1); love.graphics.print(fx.toastText, VW / 2 - f.small:getWidth(fx.toastText) / 2, 677)
  end
end

function TableView:actions(vm, buttons)
  local f, colors = self.fonts, self.cfg.COLORS
  if vm.canTruco then
    UI.button(buttons, "truco", self.cfg.trucoLabel(vm.nextTruco) .. "!", 16, 872, 330, 68, f.big, "yellow", colors)
  else
    love.graphics.setColor(1, 1, 1, 0.25); love.graphics.setFont(f.small)
    love.graphics.print(vm.maoDe11 and "sem truco na mao de 11" or "truco indisponivel", 24, 898)
  end
  UI.button(buttons, "desistir", "Correr", 356, 872, 168, 68, f.big, "ghost", colors)
end

local function modalBox(colors, y, h, VW, VH)
  love.graphics.setColor(0, 0, 0, 0.60); love.graphics.rectangle("fill", 0, 0, VW, VH, 0)
  UI.shadow(46, y, VW - 92, h, 20)
  love.graphics.setColor(colors.cream); UI.rr("fill", 46, y, VW - 92, h, 20)
end

function TableView:modals(vm, modals)
  local VW, VH, colors, f = self.cfg.VW, self.cfg.VH, self.cfg.COLORS, self.fonts
  if vm.phase == "myResponse" and vm.pendingTruco then
    local p = vm.pendingTruco
    modalBox(colors, 300, 330, VW, VH)
    love.graphics.setColor(colors.ink); love.graphics.setFont(f.big)
    local t = vm.oppLabel .. " PEDIU " .. self.cfg.trucoLabel(p.value) .. "!"
    love.graphics.print(t, VW / 2 - f.big:getWidth(t) / 2, 322)
    love.graphics.setFont(f.small)
    local s = "Valendo " .. vm.valendo .. " -> " .. p.value .. " pontos"
    love.graphics.print(s, VW / 2 - f.small:getWidth(s) / 2, 362)
    UI.button(modals, "aceitar", "ACEITAR (" .. p.value .. ")", 70, 396, VW - 140, 56, f.med, "green", colors)
    local after = self.cfg.nextTruco(p.value)
    local yCorrer = 460
    if after and not vm.maoDe11 then
      UI.button(modals, "aumentar", "PEDIR " .. self.cfg.trucoLabel(after) .. "!", 70, 460, VW - 140, 56, f.med, "orange", colors)
      yCorrer = 524
    end
    UI.button(modals, "correr", "CORRER", 70, yCorrer, VW - 140, 56, f.med, "danger", colors)
  elseif vm.phase == "roundEnd" then
    modalBox(colors, 330, 270, VW, VH)
    love.graphics.setColor(colors.ink); love.graphics.setFont(f.big)
    local t = vm.roundWinner == "mine" and "VOCE LEVOU!"
      or vm.roundWinner == "them" and (vm.oppLabel .. " LEVOU...") or "MELADA!"
    love.graphics.print(t, VW / 2 - f.big:getWidth(t) / 2, 352)
    love.graphics.setFont(f.med)
    local s = "Placar  VOCE " .. vm.myScore .. "  x  " .. vm.oppScore .. " " .. vm.oppLabel
    love.graphics.print(s, VW / 2 - f.med:getWidth(s) / 2, 396)
    UI.button(modals, "next", "PROXIMA MAO >>", 70, 456, VW - 140, 60, f.med, "blue", colors)
  elseif vm.phase == "gameOver" then
    modalBox(colors, 300, 320, VW, VH)
    love.graphics.setColor(colors.ink); love.graphics.setFont(f.big)
    local t = vm.winner == "mine" and "VOCE VENCEU!" or (vm.oppLabel .. " VENCEU...")
    love.graphics.print(t, VW / 2 - f.big:getWidth(t) / 2, 326)
    love.graphics.setFont(f.med)
    local s = "VOCE " .. vm.myScore .. "  x  " .. vm.oppScore .. " " .. vm.oppLabel
    love.graphics.print(s, VW / 2 - f.med:getWidth(s) / 2, 372)
    UI.button(modals, "restart", "JOGAR DE NOVO", 70, 436, VW - 140, 60, f.med, "green", colors)
  elseif vm.phase == "theirResponse" then
    love.graphics.setColor(0, 0, 0, 0.45); love.graphics.rectangle("fill", 60, 380, VW - 120, 70, 16)
    love.graphics.setColor(1, 1, 1); love.graphics.setFont(f.med)
    local t
    if vm.net then
      t = "aguardando " .. vm.oppLabel .. string.rep(".", 1 + math.floor(self.time * 2) % 3)
    else
      t = vm.oppLabel .. " pensando" .. string.rep(".", 1 + math.floor(self.time * 2) % 3)
    end
    love.graphics.print(t, VW / 2 - f.med:getWidth(t) / 2, 402)
  end
end

function TableView:draw(vm, fx, time)
  self.time = time
  self:background(time)
  local L = self:layout()
  self:hud(vm)
  self:mid(vm, L, time)
  self:mesa(vm, L, time)
  self:hand(vm, fx, L, time)
  local buttons, modals = {}, {}
  self:actions(vm, buttons)
  self:modals(vm, modals)
  for _, p in ipairs(fx.particles) do
    love.graphics.setColor(p.c[1], p.c[2], p.c[3], math.max(0, 1 - p.age / p.life))
    love.graphics.rectangle("fill", p.x, p.y, p.s, p.s, 3)
  end
  return L, buttons, modals
end

return TableView

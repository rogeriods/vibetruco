-- src/views/lobby_view.lua — menu e telas de LAN (host/entrar).
-- Só desenho + hitboxes; quem age é o App.
local UI = require("src.ui")

local LobbyView = {}
LobbyView.__index = LobbyView

function LobbyView.new(cfg, fonts)
  return setmetatable({ cfg = cfg, fonts = fonts }, LobbyView)
end

function LobbyView:panel(y, h)
  local VW = self.cfg.VW
  UI.shadow(32, y, VW - 64, h, 22)
  love.graphics.setColor(0.05, 0.13, 0.10, 0.90); UI.rr("fill", 32, y, VW - 64, h, 22)
  love.graphics.setColor(1, 1, 1, 0.10); love.graphics.setLineWidth(2)
  UI.rr("line", 32, y, VW - 64, h, 22); love.graphics.setLineWidth(1)
end

function LobbyView:centered(text, font, y, color)
  local VW = self.cfg.VW
  love.graphics.setFont(font)
  love.graphics.setColor(color or {1, 1, 1})
  love.graphics.print(text, VW / 2 - font:getWidth(text) / 2, y)
end

function LobbyView:title(text, y)
  self:centered(text, self.fonts.title, y, self.cfg.COLORS.yellow)
end

function LobbyView:draw(state, time)
  local VW, colors, f = self.cfg.VW, self.cfg.COLORS, self.fonts
  local buttons, fields = {}, {}

  if state.screen == "menu" then
    self:panel(150, 640)
    self:title("TRUCO", 190)
    self:centered("PAULISTA - 1V1", f.small, 262, {1, 1, 1, 0.75})
    love.graphics.setColor(1, 1, 1, 0.15)
    UI.rr("fill", 90, 300, VW - 180, 2, 1)
    UI.button(buttons, "solo", "JOGAR VS CPU", 60, 360, VW - 120, 78, f.big, "yellow", colors)
    UI.button(buttons, "host", "CRIAR SALA (LAN)", 60, 466, VW - 120, 78, f.big, "green", colors)
    UI.button(buttons, "join", "ENTRAR EM SALA", 60, 572, VW - 120, 78, f.big, "blue", colors)
    if state.status ~= "" then
      self:centered(state.status, f.small, 690, {1, 1, 1, 0.8})
    end
    self:centered("rede local - 2 jogadores", f.tiny, 860, {1, 1, 1, 0.45})

  elseif state.screen == "host" then
    self:panel(170, 620)
    self:title("SALA ABERTA", 206)
    self:centered("PASSE ESTE IP PARA SEU AMIGO", f.tiny, 290, {1, 1, 1, 0.7})
    local ip = state.hostIP
    self:centered(ip or "IP NAO DETECTADO", f.big, 322, colors.cream)
    self:centered("porta " .. tostring(self.cfg.NET.PORT), f.small, 378, {1, 1, 1, 0.65})
    if not ip then
      self:centered("veja o IP em Configuracoes > Wi-Fi", f.tiny, 404, {1, 1, 1, 0.6})
    end
    local dots = string.rep(".", 1 + math.floor(time * 2) % 3)
    self:centered("aguardando jogador" .. dots, f.med, 460, colors.yellow)
    if state.error ~= "" then
      self:centered(state.error, f.small, 510, {1, 0.45, 0.4})
    end
    UI.button(buttons, "cancelHost", "CANCELAR", 90, 640, VW - 180, 72, f.med, "ghost", colors)

  elseif state.screen == "join" then
    self:panel(150, 690)
    self:title("ENTRAR", 186)
    self:centered("IP DO HOST", f.tiny, 276, {1, 1, 1, 0.7})
    local fx, fy, fw, fh = 70, 302, VW - 140, 82
    fields.ip = { x = fx, y = fy, w = fw, h = fh }
    UI.shadow(fx, fy, fw, fh, 14)
    love.graphics.setColor(colors.cream); UI.rr("fill", fx, fy, fw, fh, 14)
    love.graphics.setColor(colors.ink); love.graphics.setFont(f.big)
    love.graphics.print(state.ip, fx + 20, fy + (fh - f.big:getHeight()) / 2)
    if state.focused and math.floor(time * 2) % 2 == 0 then
      local tx = fx + 22 + f.big:getWidth(state.ip)
      love.graphics.rectangle("fill", tx, fy + 16, 3, fh - 32, 1)
    end
    self:centered("toque no campo para digitar", f.tiny, 396, {1, 1, 1, 0.6})
    self:centered("descubra o IP do host na tela dele", f.tiny, 418, {1, 1, 1, 0.45})
    UI.button(buttons, "connect", state.connecting and "CONECTANDO..." or "CONECTAR",
      70, 462, VW - 140, 76, f.big, state.connecting and "ghost" or "green", colors)
    UI.button(buttons, "clear", "LIMPAR", 70, 560, VW - 140, 60, f.med, "ghost", colors)
    if state.error ~= "" then
      self:centered(state.error, f.small, 648, {1, 0.45, 0.4})
    end
    UI.button(buttons, "cancelJoin", "CANCELAR", 70, 700, VW - 140, 64, f.med, "danger", colors)
  end

  return buttons, fields
end

return LobbyView

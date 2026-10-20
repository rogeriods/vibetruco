-- src/app.lua — orquestrador (DIP: compõe Game + Brain + Fx + Views + rede).
-- Modos: "menu" | "solo" | "host" | "client".
local Config = require("src.config")
local Cards = require("src.cards")
local Game = require("src.game")
local Brain = require("src.ai")
local Fx = require("src.fx")
local Assets = require("src.assets")
local UI = require("src.ui")
local CardsView = require("src.views.cards_view")
local TableView = require("src.views.table_view")
local SeatView = require("src.views.seat_view")
local LobbyView = require("src.views.lobby_view")
local Server = require("src.net.server")
local Client = require("src.net.client")
local NetIP = require("src.net.ip")

local App = {}
App.__index = App

function App.new()
  local fx = Fx.new()
  local self = setmetatable({
    cfg = Config, cards = Cards, brain = Brain, fx = fx,
    assets = Assets.new(Config.RANKS, Config.SUITS),
    game = Game.new({ cards = Cards, config = Config, fx = fx }),
    fonts = {}, scale = 1, ox = 0, oy = 0,
    mode = "menu", seat = "you", vm = nil,
    buttons = {}, modals = {}, layout = nil,
    lobbyButtons = {}, lobbyFields = {},
    lobby = { screen = "menu", ip = "192.168.0.10", status = "", error = "", focused = false, connecting = false },
    server = nil, client = nil, kbOn = false,
  }, App)
  self.cardsView = CardsView.new({ assets = self.assets, config = Config, fonts = self.fonts })
  self.table = TableView.new({ config = Config, fonts = self.fonts, cardsView = self.cardsView })
  self.lobbyView = LobbyView.new(Config, self.fonts)
  return self
end

function App:load()
  love.math.setRandomSeed(os.time())
  love.graphics.setBackgroundColor(self.cfg.COLORS.bg0)
  love.keyboard.setKeyRepeat(true)
  self:loadFonts()
  self.assets:load()
  self:resize()
  self.lobby.hostIP = NetIP.localIPv4()
end

-- Carrega a pixel font do projeto com filtro nearest (nítida) e fallback seguro.
function App:loadFonts()
  local path, sizes = self.cfg.FONT_PATH, self.cfg.FONT_SIZES
  local useCustom = love.filesystem.getInfo(path) ~= nil
  for name, size in pairs(sizes) do
    local font
    if useCustom then
      local ok, f = pcall(love.graphics.newFont, path, size)
      font = (ok and f) and f or love.graphics.newFont(size)
    else
      font = love.graphics.newFont(size)
    end
    pcall(function() font:setFilter("nearest", "nearest") end)
    self.fonts[name] = font
  end
end

function App:resize()
  local sw, sh = love.graphics.getDimensions()
  self.scale = math.min(sw / self.cfg.VW, sh / self.cfg.VH)
  self.ox = (sw - self.cfg.VW * self.scale) / 2
  self.oy = (sh - self.cfg.VH * self.scale) / 2
end

function App:toVirtual(px, py) return (px - self.ox) / self.scale, (py - self.oy) / self.scale end

-- ============ REDE / SESSÃO ============

function App:closeNet()
  if self.server then self.server:destroy(); self.server = nil end
  if self.client then self.client:destroy(); self.client = nil end
  self.lobby.connecting = false
  self:setKeyboard(false)
end

function App:startSolo()
  self:closeNet()
  self.mode, self.seat = "solo", "you"
  self.game:resetMatch()
end

function App:openHost()
  self:closeNet()
  local L = self.lobby
  L.screen, L.error, L.status = "host", "", ""
  L.hostIP = NetIP.localIPv4()
  local srv, err = Server.new(self.game, self.cfg.NET.PORT, self.cfg)
  if not srv then L.error = err; return end
  self.server = srv
end

function App:startClient()
  local L = self.lobby
  if L.connecting then return end
  L.error = ""
  local ip = (L.ip or ""):gsub("%s", "")
  if not ip:match("^%d+%.%d+%.%d+%.%d+$") then L.error = "IP invalido"; return end
  self:closeNet()
  local cli, err = Client.new(ip, self.cfg.NET.PORT, self.game)
  if not cli then L.error = err; return end
  self.client = cli
  L.connecting = true
end

function App:leaveMatch(msg)
  self:closeNet()
  self.mode = "menu"
  self.lobby.screen = "menu"
  self.lobby.status = msg or ""
  self.lobby.error = ""
  self.lobby.focused = false
end

function App:setKeyboard(on)
  if not on then
    if not self.kbOn then return end
    self.kbOn = false
    love.keyboard.setTextInput(false)
    return
  end
  local f = self.lobbyFields and self.lobbyFields.ip
  if not f or self.kbOn then return end
  self.kbOn = true
  love.keyboard.setTextInput(true,
    f.x * self.scale + self.ox, f.y * self.scale + self.oy,
    f.w * self.scale, f.h * self.scale)
end

function App:viewModel()
  return SeatView.build(self.game, self.seat, self.cfg, {
    oppLabel = (self.mode == "solo") and "CPU" or "OPONENTE",
    net = (self.mode ~= "solo"),
  })
end

-- ============ UPDATE ============

local function pollNet(self, dt)
  if self.server then self.server:update(dt) end
  if self.client then self.client:update(dt) end
  local L = self.lobby
  if self.server and self.server.peer and self.mode == "menu" then
    self.mode, self.seat = "host", "you"
    L.status = ""
  end
  if self.server and self.server.peerLeft and self.mode == "host" then
    self:leaveMatch("oponente saiu")
    return
  end
  if self.client then
    if self.client.disconnected and self.mode == "client" then
      self:leaveMatch("oponente saiu")
      return
    elseif self.client.failed and self.mode == "menu" then
      L.error = self.client.reason or "falha ao conectar"
      self:closeNet()
    elseif self.client.ready and self.mode == "menu" then
      self.mode, self.seat = "client", (self.client.seat or "cpu")
      L.connecting = false
    end
  end
end

function App:updateCpu(dt)
  local g = self.game
  if g.phase == "cpuThinking" then
    g.cpuTimer = g.cpuTimer - dt
    if g.cpuTimer <= 0 then
      local d = self.brain.decideResponse(g)
      g:resolveTruco(d.accept, d.raise)
    end
    return
  end
  if g.phase ~= "play" or g.vez ~= "cpu" or g.resolveTimer > 0 then return end
  g.cpuTimer = g.cpuTimer - dt
  if g.cpuTimer > 0 then return end
  if self.brain.shouldTrucar(g) then g:requestTruco("cpu"); return end
  g:play("cpu", self.brain.chooseCard(g))
end

function App:update(dt)
  self.fx:update(dt)
  pollNet(self, dt)
  self:setKeyboard(self.mode == "menu" and self.lobby.screen == "join")
  if self.mode == "menu" then return end

  local g = self.game
  if g.resolveTimer > 0 then
    g.resolveTimer = g.resolveTimer - dt
    if g.resolveTimer <= 0 then g.resolveTimer = -1; g:resolveVaza() end
    return
  end
  if self.mode == "solo" then self:updateCpu(dt) end
end

-- ============ DRAW ============

function App:draw()
  love.graphics.push()
  love.graphics.translate(self.ox, self.oy)
  love.graphics.scale(self.scale, self.scale)
  if self.fx.shakeT > 0 then
    love.graphics.translate(love.math.random(-6, 6) * self.fx.shakeT * 3, love.math.random(-6, 6) * self.fx.shakeT * 3)
  end

  if self.mode == "menu" then
    self.table:background(self.fx.time)
    local buttons, fields = self.lobbyView:draw(self.lobby, self.fx.time)
    self.lobbyButtons, self.lobbyFields = buttons, fields
    self.buttons, self.modals = {}, {}
  else
    local vm = self:viewModel()
    local L, buttons, modals = self.table:draw(vm, self.fx, self.fx.time)
    self.layout, self.buttons, self.modals = L, buttons, modals
  end

  love.graphics.pop()
  love.graphics.setColor(self.cfg.COLORS.bg0)
  if self.ox > 0 then
    love.graphics.rectangle("fill", 0, 0, self.ox, love.graphics.getHeight())
    love.graphics.rectangle("fill", love.graphics.getWidth() - self.ox, 0, self.ox, love.graphics.getHeight())
  end
  if self.oy > 0 then
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), self.oy)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - self.oy, love.graphics.getWidth(), self.oy)
  end
end

-- ============ INPUT ============

function App:playCard(i)
  if self.client then return self.client:send({ t = "play", i = i }) end
  return self.game:play(self.seat, i)
end

function App:askTruco()
  if self.client then return self.client:send({ t = "truco" }) end
  return self.game:requestTruco(self.seat)
end

function App:respond(accepted, raised)
  if self.client then return self.client:send({ t = "respond", a = accepted, r = raised }) end
  return self.game:resolveTruco(accepted, raised)
end

function App:nextMao()
  if self.client then return self.client:send({ t = "next" }) end
  return self.game:nextMao()
end

function App:restart()
  if self.client then return self.client:send({ t = "rematch" }) end
  return self.game:rematch()
end

function App:forfeit()
  if self.client then return self.client:send({ t = "forfeit" }) end
  return self.game:forfeit(self.seat)
end

function App:gamePress(x, y)
  local vm = self:viewModel()
  local m = UI.hit(self.modals, x, y)
  if m then
    if m == "aceitar" then self:respond(true, false)
    elseif m == "aumentar" then self:respond(true, true)
    elseif m == "correr" then self:respond(false, false)
    elseif m == "next" then self:nextMao()
    elseif m == "restart" then self:restart() end
    return
  end
  if vm.phase ~= "play" then return end
  local b = UI.hit(self.buttons, x, y)
  if b == "truco" then self:askTruco(); return
  elseif b == "desistir" then self:forfeit(); return end
  if vm.myTurn then
    for i = 1, #vm.myHand do
      local s = self.layout and self.layout.handCards[i]
      if s and x >= s.x - 8 and x <= s.x + s.w + 8 and y >= s.y - 24 and y <= s.y + s.h + 16 then
        self:playCard(i)
        return
      end
    end
  end
end

function App:lobbyButton(id)
  local L = self.lobby
  if id == "solo" then self:startSolo()
  elseif id == "host" then self:openHost()
  elseif id == "join" then L.screen, L.error, L.status, L.focused = "join", "", "", true
  elseif id == "cancelHost" then self:closeNet(); L.screen, L.status = "menu", ""
  elseif id == "cancelJoin" then self:closeNet(); L.screen, L.focused = "menu", false
  elseif id == "connect" then self:startClient()
  elseif id == "clear" then L.ip, L.error = "", "" end
end

function App:pressVirtual(x, y)
  if self.mode == "menu" then
    local id = UI.hit(self.lobbyButtons, x, y)
    if id then self:lobbyButton(id); return end
    local f = self.lobbyFields.ip
    if self.lobby.screen == "join" and f
      and x >= f.x and x <= f.x + f.w and y >= f.y and y <= f.y + f.h then
      self.lobby.focused = true
      self:setKeyboard(true)
    end
    return
  end
  self:gamePress(x, y)
end

function App:textinput(t)
  if self.mode ~= "menu" or self.lobby.screen ~= "join" then return end
  if #self.lobby.ip >= 15 then return end
  if t:match("^[%d%.]+$") then self.lobby.ip = self.lobby.ip .. t end
end

function App:key(k)
  local L = self.lobby
  if self.mode == "menu" then
    if L.screen == "join" then
      if k == "backspace" then L.ip = L.ip:sub(1, -2)
      elseif k == "return" or k == "kpenter" then self:startClient()
      elseif k == "escape" then self:closeNet(); L.screen, L.focused = "menu", false end
    elseif L.screen == "host" then
      if k == "escape" then self:closeNet(); L.screen = "menu" end
    elseif k == "escape" then
      love.event.quit()
    end
    return
  end
  if k == "escape" then self:leaveMatch("voce saiu da partida"); return end
  if k == "1" then self:playCard(1)
  elseif k == "2" then self:playCard(2)
  elseif k == "3" then self:playCard(3)
  elseif k == "t" then self:askTruco()
  elseif k == "return" or k == "space" then
    local vm = self:viewModel()
    if vm.phase == "roundEnd" then self:nextMao()
    elseif vm.phase == "gameOver" then self:restart() end
  end
end

return App

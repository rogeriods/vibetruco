-- src/net/server.lua — host autoritativo.
-- Só ele roda as regras; o convidado manda intenções e recebe snapshots.
local Protocol = require("src.net.protocol")

-- No LÖVE, ENet vem como módulo (não como global).
local okEnet, enet = pcall(require, "enet")
if not okEnet then enet = nil end

local Server = {}
Server.__index = Server

function Server.new(game, port, cfg)
  if not enet then return nil, "ENet indisponivel" end
  local host = enet.host_create("*:" .. tostring(port), 8, 2, 0, 0)
  if not host then return nil, "porta " .. tostring(port) .. " em uso" end
  return setmetatable({
    game = game, host = host, peer = nil,
    cfg = cfg, acc = 0, peerLeft = false,
  }, Server)
end

function Server:onJoin(peer)
  self.peer = peer
  self.peerLeft = false
  self.game:resetMatch()
  peer:send(Protocol.encode({ t = "welcome", seat = "cpu" }), 1, "reliable")
  self:sendState()
end

function Server:onMessage(msg)
  local g = self.game
  local t = msg.t
  if t == "play" then
    if type(msg.i) == "number" then g:play("cpu", msg.i) end
  elseif t == "truco" then
    g:requestTruco("cpu")
  elseif t == "respond" then
    g:resolveTruco(msg.a == true, msg.r == true)
  elseif t == "next" then
    g:nextMao()
  elseif t == "rematch" then
    g:rematch()
  elseif t == "forfeit" then
    g:forfeit("cpu")
  end
  self:sendState()
end

-- Snapshot do ponto de vista do convidado: a mão do host vai oculta.
-- (anti-cheat básico: o cliente nunca recebe cartas que não são dele)
function Server:stateForGuest()
  local s = self.game:snapshot()
  local hide = {}
  for i = 1, #(s.youHand or {}) do hide[i] = { rank = "?", suit = "?", id = -i } end
  s.youHand = hide
  return s
end

function Server:sendState()
  if not self.peer then return end
  self.peer:send(Protocol.encode({ t = "state", s = self:stateForGuest() }), 1, "reliable")
end

function Server:update(dt)
  while true do
    local ev = self.host:service(0)
    if not ev then break end
    if ev.type == "connect" then
      if self.peer then
        ev.peer:disconnect(1)
      else
        self:onJoin(ev.peer)
      end
    elseif ev.type == "disconnect" then
      if ev.peer and ev.peer == self.peer then
        self.peer = nil
        self.peerLeft = true
      end
    elseif ev.type == "receive" then
      if ev.peer == self.peer then
        local msg = Protocol.decode(ev.data)
        if msg then self:onMessage(msg) end
      end
    end
  end
  if self.peer then
    self.acc = self.acc + dt
    local step = 1 / (self.cfg and self.cfg.NET.STATE_HZ or 10)
    if self.acc >= step then
      self.acc = 0
      self:sendState()
    end
  end
end

function Server:destroy()
  if self.host then
    self.host:destroy()
    self.host = nil
  end
  self.peer = nil
end

return Server

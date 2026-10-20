-- src/net/client.lua — convidado burro: manda intenções, espelha snapshots.
local Protocol = require("src.net.protocol")

local okEnet, enet = pcall(require, "enet")
if not okEnet then enet = nil end

local Client = {}
Client.__index = Client

local CONNECT_TIMEOUT = 8

function Client.new(ip, port, game)
  if not enet then return nil, "ENet indisponivel" end
  local host = enet.host_create(nil, 4, 2, 0, 0)
  if not host then return nil, "sem rede" end
  local peer = host:connect(ip .. ":" .. tostring(port), 2)
  if not peer then host:destroy(); return nil, "IP invalido" end
  return setmetatable({
    host = host, peer = peer, game = game,
    started = love.timer.getTime(),
    ready = false, failed = false, disconnected = false,
    reason = nil, seat = "cpu",
  }, Client)
end

function Client:handle(msg)
  if msg.t == "welcome" then
    self.seat = msg.seat or "cpu"
    self.ready = true
  elseif msg.t == "state" and type(msg.s) == "table" then
    self.game:restore(msg.s)
  end
end

function Client:update(dt)
  local now = love.timer.getTime()
  while true do
    local ev = self.host:service(0)
    if not ev then break end
    if ev.type == "connect" then
      self.connected = true
    elseif ev.type == "disconnect" then
      if self.ready then self.disconnected = true
      else self.failed, self.reason = true, "nao conseguiu conectar" end
    elseif ev.type == "receive" then
      local msg = Protocol.decode(ev.data)
      if msg then self:handle(msg) end
    end
  end
  if not self.ready and not self.failed and now - self.started > CONNECT_TIMEOUT then
    self.failed, self.reason = true, "tempo esgotado"
  end
end

function Client:send(msg)
  if not self.peer or not self.ready then return false end
  self.peer:send(Protocol.encode(msg), 1, "reliable")
  return true
end

function Client:destroy()
  if self.host then
    self.host:destroy()
    self.host = nil
  end
  self.peer = nil
end

return Client

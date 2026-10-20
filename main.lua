-- main.lua — adapter fino do LÖVE (SRP: só delega pro App).
-- Domínio em src/game.lua, IA em src/ai.lua, rede em src/net/, desenho em src/views/.
local App = require("src.app")

local app = App.new()
local tests = nil

function love.load(args)
  for _, a in ipairs(args or {}) do
    if a == "--test-net" then
      tests = require("tests.net_smoke")
      tests.start()
      return
    end
  end
  app:load()
end

function love.resize()
  if not tests then app:resize() end
end

function love.update(dt)
  if tests then tests.update(dt) else app:update(dt) end
end

function love.draw()
  if tests then tests.draw() else app:draw() end
end

function love.touchpressed(_, px, py)
  if tests then return end
  local x, y = app:toVirtual(px, py)
  app:pressVirtual(x, y)
end

function love.mousepressed(px, py)
  if tests then return end
  local x, y = app:toVirtual(px, py)
  app:pressVirtual(x, y)
end

function love.textinput(t)
  if tests then return end
  app:textinput(t)
end

function love.keypressed(k)
  if tests then return end
  app:key(k)
end

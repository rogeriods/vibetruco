-- src/fx.lua — efeitos de apresentação (partículas, shake, toast).
-- SRP: não sabe nada de truco; só acumula e evolui efeitos.
local Fx = {}
Fx.__index = Fx

function Fx.new()
  return setmetatable({ particles = {}, shakeT = 0, toastText = "", toastT = 0, time = 0 }, Fx)
end

function Fx:toast(text, dur)
  self.toastText, self.toastT = text, dur or 2.2
end

function Fx:shake(t) self.shakeT = math.max(self.shakeT, t) end

function Fx:burst(x, y, color, n)
  for _ = 1, (n or 20) do
    self.particles[#self.particles + 1] = {
      x = x, y = y,
      vx = love.math.random(-220, 220), vy = love.math.random(-320, 120),
      life = love.math.random() * 0.7 + 0.3, age = 0,
      c = color, s = love.math.random(4, 9), g = 600,
    }
  end
end

function Fx:update(dt)
  self.time = self.time + dt
  if self.shakeT > 0 then self.shakeT = self.shakeT - dt end
  if self.toastT > 0 then self.toastT = self.toastT - dt end
  for i = #self.particles, 1, -1 do
    local p = self.particles[i]
    p.age = p.age + dt
    p.vy = p.vy + p.g * dt
    p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
    if p.age >= p.life then table.remove(self.particles, i) end
  end
end

return Fx

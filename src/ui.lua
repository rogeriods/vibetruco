-- src/ui.lua — primitivos de desenho (SRP: só geometria/estilo, sem regra de jogo).
local UI = {}

function UI.rr(mode, x, y, w, h, r)
  love.graphics.rectangle(mode, x, y, w, h, r or 12, r or 12)
end

function UI.shadow(x, y, w, h, r)
  love.graphics.setColor(0, 0, 0, 0.35)
  UI.rr("fill", x, y + 5, w, h, r)
end

function UI.hit(list, x, y)
  for _, b in ipairs(list) do
    if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then return b.id end
  end
  return nil
end

-- Desenha e registra o botão na lista (ISP: view decide a lista que recebe).
function UI.button(registry, id, label, x, y, w, h, font, style, colors)
  registry[#registry + 1] = { id = id, x = x, y = y, w = w, h = h }
  local pal, txt = colors.yellow, colors.ink
  if style == "ghost" then pal, txt = {1,1,1,0.14}, {1,1,1}
  elseif style == "danger" then pal, txt = colors.red, {1,1,1}
  elseif style == "green" then pal, txt = colors.green, {1,1,1}
  elseif style == "orange" then pal, txt = colors.orange, {1,1,1}
  elseif style == "blue" then pal, txt = colors.blue, {1,1,1} end
  UI.shadow(x, y, w, h, 14)
  love.graphics.setColor(pal); UI.rr("fill", x, y, w, h, 14)
  love.graphics.setColor(1, 1, 1, 0.25); UI.rr("fill", x + 4, y + 4, w - 8, h * 0.42, 10)
  love.graphics.setColor(txt); love.graphics.setFont(font)
  love.graphics.print(label, x + (w - font:getWidth(label)) / 2, y + (h - font:getHeight()) / 2)
end

return UI

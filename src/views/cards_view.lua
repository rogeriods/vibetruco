-- src/views/cards_view.lua — desenha faces/versos (DIP: recebe assets/fonts, não cria nada).
local UI = require("src.ui")

local CardsView = {}
CardsView.__index = CardsView

function CardsView.new(deps)
  return setmetatable({ assets = deps.assets, cfg = deps.config, fonts = deps.fonts }, CardsView)
end

local function isRed(suit) return suit == "ouros" or suit == "copas" end

function CardsView:face(card, manilha, x, y, w, h, opts, time)
  opts = opts or {}
  local colors = self.cfg.COLORS
  local isMan = (card.rank == manilha)
  love.graphics.push()
  love.graphics.translate(x + w / 2, y + h / 2)
  love.graphics.rotate(math.rad(opts.tilt or 0))
  love.graphics.translate(-w / 2, -h / 2)
  UI.shadow(0, 0, w, h, 14)
  if isMan then
    love.graphics.setColor(colors.gold[1], colors.gold[2], colors.gold[3], 0.55 + 0.25 * math.sin(time * 6))
    UI.rr("fill", -5, -5, w + 10, h + 10, 18)
  end
  local img = self.assets:face(card)
  if img then
    love.graphics.setColor(1, 1, 1)
    local iw, ih = img:getDimensions()
    love.graphics.draw(img, 0, 0, 0, w / iw, h / ih)
    love.graphics.setColor(isMan and colors.gold or (opts.selected and colors.blue or {1,1,1,0.9}))
    love.graphics.setLineWidth(isMan and 5 or 2)
    UI.rr("line", 1, 1, w - 2, h - 2, 14)
    love.graphics.setLineWidth(1)
    if isMan then
      love.graphics.setColor(1, 0.85, 0.2); love.graphics.setFont(self.fonts.tiny)
      love.graphics.print("MANILHA", (w - self.fonts.tiny:getWidth("MANILHA")) / 2, 4)
    end
    love.graphics.pop()
    return
  end
  love.graphics.setColor(colors.cream); UI.rr("fill", 0, 0, w, h, 14)
  love.graphics.setColor(isMan and colors.gold or (opts.selected and colors.blue or {0.85,0.85,0.85}))
  UI.rr("line", 0, 0, w, h, 14)
  love.graphics.setLineWidth(isMan and 5 or 3); UI.rr("line", 3, 3, w - 6, h - 6, 11)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(isRed(card.suit) and colors.red or colors.ink)
  love.graphics.setFont(self.fonts.med); love.graphics.print(card.rank, 10, 8)
  love.graphics.setFont(self.fonts.small); love.graphics.print(self.cfg.SUIT_SYM[card.suit], 11, 30)
  love.graphics.setFont(self.fonts.suit)
  local sw = self.fonts.suit:getWidth(self.cfg.SUIT_SYM[card.suit])
  love.graphics.print(self.cfg.SUIT_SYM[card.suit], (w - sw) / 2, h * 0.30)
  love.graphics.setFont(self.fonts.med)
  love.graphics.print(card.rank, w - self.fonts.med:getWidth(card.rank) - 10, h - 30)
  if isMan then
    love.graphics.setColor(0.45, 0.32, 0.0); love.graphics.setFont(self.fonts.tiny)
    local t = "MANILHA"
    love.graphics.print(t, (w - self.fonts.tiny:getWidth(t)) / 2, h - 16)
  end
  love.graphics.pop()
end

function CardsView:back(x, y, w, h, tilt)
  local colors = self.cfg.COLORS
  love.graphics.push()
  love.graphics.translate(x + w / 2, y + h / 2)
  love.graphics.rotate(math.rad(tilt or 0))
  love.graphics.translate(-w / 2, -h / 2)
  UI.shadow(0, 0, w, h, 12)
  if self.assets.back then
    love.graphics.setColor(1, 1, 1)
    local iw, ih = self.assets.back:getDimensions()
    love.graphics.draw(self.assets.back, 0, 0, 0, w / iw, h / ih)
    love.graphics.setColor(colors.yellow); love.graphics.setLineWidth(3)
    UI.rr("line", 1, 1, w - 2, h - 2, 12)
    love.graphics.setLineWidth(1)
    love.graphics.pop()
    return
  end
  love.graphics.setColor(colors.red); UI.rr("fill", 0, 0, w, h, 12)
  love.graphics.setColor(colors.yellow); love.graphics.setLineWidth(3); UI.rr("line", 0, 0, w, h, 12)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(0.55, 0.07, 0.13)
  for i = -h, w, 14 do love.graphics.line(i, 0, i + h, h) end
  love.graphics.setColor(colors.yellow); love.graphics.setFont(self.fonts.small)
  love.graphics.print("*", (w - self.fonts.small:getWidth("*")) / 2, h / 2 - 10)
  love.graphics.pop()
end

return CardsView

-- src/assets.lua — carrega PNGs opcionais das cartas (fallback = procedural).
-- SRP: só resolve arquivos -> Image. Convenção: assets/cartas/<rank>-<naipe>.png + verso.png
local Assets = {}
Assets.__index = Assets

function Assets.new(ranks, suits)
  return setmetatable({ ranks = ranks, suits = suits, faces = {}, back = nil }, Assets)
end

function Assets:load()
  self.faces, self.back = {}, nil
  for _, s in ipairs(self.suits) do
    for _, r in ipairs(self.ranks) do
      local path = "assets/cartas/" .. r .. "-" .. s .. ".png"
      if love.filesystem.getInfo(path) then
        local ok, img = pcall(love.graphics.newImage, path)
        if ok and img then img:setFilter("linear", "linear"); self.faces[r .. "-" .. s] = img end
      end
    end
  end
  if love.filesystem.getInfo("assets/cartas/verso.png") then
    local ok, img = pcall(love.graphics.newImage, "assets/cartas/verso.png")
    if ok and img then img:setFilter("linear", "linear"); self.back = img end
  end
end

function Assets:face(card) return self.faces[card.rank .. "-" .. card.suit] end

return Assets

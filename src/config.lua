-- src/config.lua — única fonte de constantes (SRP: só dados de configuração).
local Config = {
  VW = 540, VH = 960,
  RANKS = {"4","5","6","7","Q","J","K","A","2","3"},
  RANK_POWER = {["4"]=1,["5"]=2,["6"]=3,["7"]=4,["Q"]=5,["J"]=6,["K"]=7,["A"]=8,["2"]=9,["3"]=10},
  SUITS = {"ouros","espadas","copas","paus"},
  SUIT_SYM = {ouros="♦", espadas="♠", copas="♥", paus="♣"},
  SUIT_POWER = {ouros=1, espadas=2, copas=3, paus=4},
  TRUCO_LADDER = {1, 3, 6, 9, 12},
  TRUCO_LABEL = {[3]="TRUCO", [6]="SEIS", [9]="NOVE", [12]="DOZE"},
  MAX_SCORE = 12,
  -- Fonte pixel-art (vem da pasta do projeto; cai pro padrão do LÖVE se faltar).
  FONT_PATH = "assets/fontes/m6x11.ttf",
  FONT_SIZES = { title = 54, big = 33, med = 22, small = 16, tiny = 11, suit = 66 },
  NET = { PORT = 6789, STATE_HZ = 10 },
  COLORS = {
    bg0={0.03,0.15,0.11}, bg1={0.06,0.42,0.29}, bgSwirl={0.10,0.55,0.38,0.35},
    cream={0.99,0.96,0.89}, ink={0.10,0.12,0.14}, red={0.86,0.15,0.22},
    blue={0.20,0.45,0.95}, yellow={1.0,0.81,0.25}, gold={1.0,0.78,0.10},
    green={0.13,0.77,0.37}, dark={0.07,0.11,0.10},
    ghost={1,1,1,0.16}, orange={0.98,0.45,0.09},
  },
}

function Config.nextTruco(valendo)
  for i, v in ipairs(Config.TRUCO_LADDER) do
    if v == valendo then return Config.TRUCO_LADDER[i + 1] end
  end
  return nil
end

function Config.trucoLabel(v)
  return Config.TRUCO_LABEL[v] or tostring(v)
end

return Config

-- src/cards.lua — regras puras do baralho (sem dependência de love ou UI).
-- SRP: só conhece ranks/naipes. Recebe tabelas por parâmetro (DIP: não importa Config).
local Cards = {}

function Cards.nextRank(ranks, rank)
  for i, v in ipairs(ranks) do
    if v == rank then return ranks[(i % #ranks) + 1] end
  end
  return ranks[1]
end

function Cards.isManilha(card, manilha)
  return card.rank == manilha
end

function Cards.power(card, manilha, rankPower, suitPower)
  if card.rank == manilha then return 100 + (suitPower[card.suit] or 0) end
  return rankPower[card.rank] or 0
end

function Cards.newDeck(ranks, suits)
  local deck, id = {}, 0
  for _, s in ipairs(suits) do
    for _, r in ipairs(ranks) do
      id = id + 1
      deck[#deck + 1] = { rank = r, suit = s, id = id }
    end
  end
  return deck
end

-- randInt(a, b) injetável: em produção love.math.random, em teste função fake.
function Cards.shuffle(deck, randInt)
  for i = #deck, 2, -1 do
    local j = randInt(1, i)
    deck[i], deck[j] = deck[j], deck[i]
  end
end

function Cards.handStrength(hand, manilha, rankPower, suitPower)
  local s = 0
  for _, c in ipairs(hand) do s = s + Cards.power(c, manilha, rankPower, suitPower) end
  return s
end

function Cards.countManilhas(hand, manilha)
  local n = 0
  for _, c in ipairs(hand) do if c.rank == manilha then n = n + 1 end end
  return n
end

function Cards.key(card) return card.rank .. "-" .. card.suit end

return Cards

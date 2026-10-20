-- src/net/protocol.lua — serialização das mensagens (formato Lua literals).
-- Decodifica em ambiente vazio e com pcall: nada de executar código arbitrário da rede.
local Protocol = {}

local function fmtnum(n)
  if n % 1 == 0 then return string.format("%d", n) end
  return string.format("%.17g", n)
end

local function enc(v, out)
  local t = type(v)
  if t == "nil" then out[#out + 1] = "nil"
  elseif t == "boolean" then out[#out + 1] = v and "true" or "false"
  elseif t == "number" then out[#out + 1] = fmtnum(v)
  elseif t == "string" then out[#out + 1] = string.format("%q", v)
  elseif t == "table" then
    out[#out + 1] = "{"
    for k, val in pairs(v) do
      if type(k) == "number" then out[#out + 1] = "[" .. fmtnum(k) .. "]="
      elseif type(k) == "string" then out[#out + 1] = "[" .. string.format("%q", k) .. "]="
      else out[#out + 1] = "[nil]=" end
      enc(val, out)
      out[#out + 1] = ","
    end
    out[#out + 1] = "}"
  else out[#out + 1] = "nil" end
end

function Protocol.encode(msg)
  local out = {}
  enc(msg, out)
  return table.concat(out)
end

function Protocol.decode(data)
  if type(data) ~= "string" or #data > 65536 then return nil end
  local loader = loadstring or load
  local chunk = loader("return " .. data)
  if not chunk then return nil end
  if setfenv then setfenv(chunk, {}) end
  local ok, res = pcall(chunk)
  if ok and type(res) == "table" then return res end
  return nil
end

return Protocol

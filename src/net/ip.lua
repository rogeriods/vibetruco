-- src/net/ip.lua — descobre o IPv4 local exibindo-o pro host.
-- Melhor esforço: desktop usa ipconfig/ifconfig. Em Android pode falhar (retorna nil).
local IP = {}

local function run(cmd)
  local ok, pipe = pcall(io.popen, cmd)
  if not ok or not pipe then return nil end
  local out = pipe:read("*a")
  pcall(pipe.close, pipe)
  return out
end

local function rank(ip)
  if ip:match("^192%.168%.") then return 1 end
  if ip:match("^10%.") then return 2 end
  if ip:match("^172%.(1[6-9]|2%d|3[01])%.") then return 3 end
  if ip:match("^169%.254%.") then return 9 end
  return 5
end

function IP.localIPv4()
  local isWindows = package.config:sub(1, 1) == "\\"
  local out = isWindows and run("ipconfig") or run("ifconfig 2>/dev/null")
  if not out then return nil end
  local seen, list = {}, {}
  for ip in out:gmatch("(%d+%.%d+%.%d+%.%d+)") do
    local bad = ip:match("^127%.") or ip:match("^0%.") or ip:match("^255%.")
    if not bad and not seen[ip] then
      seen[ip] = true
      list[#list + 1] = { ip = ip, r = rank(ip) }
    end
  end
  table.sort(list, function(a, b) return a.r < b.r end)
  return list[1] and list[1].ip or nil
end

return IP

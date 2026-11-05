dofile(arg[1])
local n, ok = 0, 0
for line in io.lines(arg[2]) do
  if #line > 0 then
    n = n + 1
    local rec = { message = line }
    local _, _, out = parse_modsecurity_keys(nil, 0, rec)
    print((out and out["modsecurity"]) or '{"_filter":"did-not-fire"}')
  end
end

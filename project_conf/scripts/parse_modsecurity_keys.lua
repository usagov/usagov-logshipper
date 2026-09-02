-- Gets modsecurity record and returns a record with a json string of the modsecurity attributes.
--
-- Parses ModSecurity's nginx error-log alert line, e.g.
--   2026/08/27 18:30:36 [info] 280#280: *4009 ModSecurity: Warning. Matched
--   "Operator `Rx' with parameter `^0?$' against variable `ARGS:q' (Value: `x' )
--   [file "..."] [line "171"] [id "920170"] [msg "..."] [tag "a"] [tag "b"]
--   ..., client: 1.2.3.4, server: _, request: "GET / HTTP/1.1", host: "..."
--
-- The bracketed fields are always of the shape [word "value"]. Regex operator
-- parameters also contain square brackets -- [^>]*, [\s\S], [\d.] -- but never
-- in that shape, so matching the full shape rather than any [...] is what keeps
-- @rx rules parsing correctly.

-- Escape a Lua string for inclusion in a JSON string literal.
-- Backslash must be escaped first, or it would double-escape the others.
local function json_escape(s)
  s = s:gsub('\\', '\\\\')
  s = s:gsub('"', '\\"')
  s = s:gsub('%c', function(c) return string.format('\\u%04X', string.byte(c)) end)
  return s
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- The human-readable part: from "ModSecurity" up to the first real bracketed
-- field. Cutting at the first "[" instead would truncate inside the regex that
-- @rx rules print as their operator parameter.
local function extract_modsecurity_message_string(s)
  local startIndex = s:find("ModSecurity", 1, true)
  if not startIndex then
    return nil
  end
  local tail = s:sub(startIndex)
  local cut = tail:find('%s%[[%w_]+%s"')
  if cut then
    tail = tail:sub(1, cut - 1)
  end
  return trim(tail)
end

-- All [key "value"] fields. Repeated keys (tag) are joined rather than emitted
-- twice, which would produce duplicate JSON keys and lose all but the last.
local function extract_bracketed_data(s, out)
  local repeated = {}
  for key, value in s:gmatch('%[([%w_]+)%s"([^"]*)"%]') do
    if out[key] == nil then
      out[key] = value
    else
      if repeated[key] == nil then
        repeated[key] = { out[key] }
      end
      table.insert(repeated[key], value)
    end
  end
  for key, list in pairs(repeated) do
    out[key] = table.concat(list, ",")
  end
end

-- nginx's own prefix: "2026/08/27 18:30:36 [info] 280#280: *4009 ..."
-- Anchored so a bare [word] inside a regex cannot be mistaken for the level.
local function extract_nginx_prefix(s, out)
  local level = s:match('^%s*%d+/%d+/%d+%s+%d+:%d+:%d+%s+%[(%a+)%]')
  if level then
    out["level"] = level
  end
  local client = s:match('%[client%s+([^%]]+)%]')
  if client then
    out["client"] = trim(client)
  end
end

-- The unbracketed trailer: ", client: 1.2.3.4, server: _, request: "...", host: "..."
-- Scanned only from ", client:" onward so that commas inside a regex or inside
-- [data "..."] cannot produce spurious keys.
local function extract_trailing_data(s, out)
  local tpos = s:find(',%s*client:%s')
  if not tpos then
    return
  end
  for key, value in s:sub(tpos):gmatch(',%s*([%w_]+):%s*([^,]+)') do
    value = trim(value)
    local unquoted = value:match('^"(.*)"$')
    out[key] = unquoted or value
  end
end

local modsecurity_attributes_json_string = function (orig_string)
  local fields = {}

  extract_nginx_prefix(orig_string, fields)
  extract_bracketed_data(orig_string, fields)
  extract_trailing_data(orig_string, fields)

  local message = extract_modsecurity_message_string(orig_string)
  fields["message"] = message or "none"

  -- Stable key order keeps the output diffable; message first for readability.
  local keys = {}
  for k in pairs(fields) do
    if k ~= "message" then
      table.insert(keys, k)
    end
  end
  table.sort(keys)
  table.insert(keys, 1, "message")

  local parts = {}
  for _, k in ipairs(keys) do
    table.insert(parts, '"' .. json_escape(k) .. '":"' .. json_escape(tostring(fields[k])) .. '"')
  end

  -- Concatenate attributes into a JSON formatted string for New Relic parsing
  return "{" .. table.concat(parts, ",") .. "}"
end

-- The --luacheck:ignore comment suppresses a warning about setting
-- a global variable and that this is an unused function
-- (like most scripts, this function is called via fluentbit.conf,
-- which expects it to be defined in this way)
function parse_modsecurity_keys (_, timestamp, record) --luacheck: ignore
  if (record["message"] ~= nil and string.find(string.lower(record["message"]), "modsecurity") ~= nil) then
    record["modsecurity"] = modsecurity_attributes_json_string(record["message"])
  end
   -- 2 leaves timestamp unchanged
  return 2, timestamp, record
end

-- Gets modsecurity record and returns a record with a json string of the modsecurity attributes.

local modsecurity_attributes_json_string = function (orig_string)
  message, body, client, server, request, host = orig_string:match("ModSecurity:(.-)%[(.-)%], client: (.-), server: (.-), request: (.-), host: (.-)$")

  attributes = {}
  table.insert(attributes, '"message":"' .. message:gsub("^%s*(.-)%s*$", "%1"):gsub('"', '\\"') .. '"')
  table.insert(attributes, '"server":"' .. server:gsub("^%s*(.-)%s*$", "%1"):gsub('"', '\\"') .. '"')
  table.insert(attributes, '"request":' .. request:gsub("^%s*(.-)%s*$", "%1"):gsub('"', '\\"'))
  table.insert(attributes, '"host":' .. host:gsub("^%s*(.-)%s*$", "%1"):gsub('"', '\\"'))
  for attribute in string.gmatch(orig_string, "%[(.-)%]") do

    -- Split attribute by whitespace
    key, value = attribute:match("(%S+)%s+(.*)")
    if key and value then
      if key == "client" then
        value = '"' .. value:gsub("^%s*(.-)%s*$", "%1") .. '"'
      else
        value = value:gsub("^%s*(.-)%s*$", "%1")
      end
      attribute = '"' .. key .. '":' .. value:gsub('"', '\\"')
    else
      attribute = '"level":"' .. attribute:gsub("^%s*(.-)%s*$", "%1"):gsub('"', '\\"') .. '"'
    end
    table.insert(attributes, attribute)
  end

  -- Concatenate attributes into a JSON formatted string for New Relic parsing
  json_string = table.concat(attributes, ",")

  -- wrap drupal field in brackets to make it parsable json
  local final_string = "{" .. json_string .. "}"
  return final_string
end

-- The --luacheck:ignore comment suppresses a warning about setting
-- a global variable and that this is an unused function
-- (like most scripts, this function is called via fluentbit.conf,
-- which expects it to be defined in this way)
function parse_modsecurity_keys (_, timestamp, record) --luacheck: ignore
  if (record["message"] ~= nil and string.find(record["message"], "ModSecurity")) then
    record["modsecurity"] = modsecurity_attributes_json_string(record["message"])
  end
   -- 2 leaves timestamp unchanged
  return 2, timestamp, record
end
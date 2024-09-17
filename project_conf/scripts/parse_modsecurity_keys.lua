-- Gets modsecurity record and returns a record with a json string of the modsecurity attributes.

local modsecurity_attributes_json_string = function (orig_string)
  -- Extract the ModSecurity text from the message
  local modsecurity_text = orig_string:match("ModSecurity:(.-)%[")

  -- Find text within square brackets and store in an array
  local attributes = {}
  table.insert(attributes, '"message":' .. modsecurity_text:gsub("^%s*(.-)%s*$", "%1"))
  for attribute in string.gmatch(orig_string, "%[(.-)%]") do

    -- Split attribute by whitespace
    local key, value = attribute:match("(%S+)%s+(.*)")
    if key and value then
      attribute = '"' .. key .. '":' .. value:gsub("^%s*(.-)%s*$", "%1")
    else
      attribute = '"level":"' .. attribute:gsub("^%s*(.-)%s*$", "%1") .. '"'
    end
    table.insert(attributes, attribute)
  end

  -- Concatenate attributes into a JSON string
  local final_string = table.concat(attributes, ",")

  -- wrap modsecurity field in brackets to make it parsable json
  -- local final_string = "{" .. final_string .. "}"
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
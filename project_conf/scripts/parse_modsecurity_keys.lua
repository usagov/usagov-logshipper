-- Gets modsecurity record and returns a record with a json string of the modsecurity attributes.

-- This function is used to extract the main ModSecurity message from the message field
function extract_modsecurity_message_string(s)
  local startIndex = s:find("ModSecurity")
  if startIndex then
      local bracketIndex = s:find("%[", startIndex)

      if bracketIndex then
          return s:sub(startIndex, bracketIndex - 1)
      else
          return '"message":"' .. s:sub(startIndex) .. '"'
      end
  else
      return '"message":"none"'
  end
end

-- This function is used to extract the data from the bracketed sections of the message field
function extract_bracketed_data(s)
  local pattern = "%[(.-)%]"
  local matches = {}
  for match in s:gmatch(pattern) do
      local key, value = match:match("([^ ]+) (.+)")
      if key then
          table.insert(matches, '"' .. key .. '":"' .. (value or "") .. '"')
      else
          -- the only time there is no key is when the match is the level
          table.insert(matches, '"level":"' .. (match or "") .. '"')
      end
  end
  return matches
end

-- This function is used to extract the data from the final four unbracketed attributes of the message field
function extract_trailing_data(s)
  local pattern = ", (%w+): (.+)"
  local matches = {}
  for key, value in s:gmatch(pattern) do
      table.insert(matches, '"' .. key .. '":"' .. value .. '"')
  end
  return matches
end

local function tableMerge(result, ...)
  for _, t in ipairs({...}) do
    for _, v in ipairs(t) do
      table.insert(result, v)
    end
  end
end

local modsecurity_attributes_json_string = function (orig_string)
  local attributes = {}
  local message = extract_modsecurity_message_string(orig_string)
  local bracketed = extract_bracketed_data(orig_string)
  local trailing = extract_trailing_data(orig_string)

  tableMerge(attributes, {message}, bracketed, trailing)

  -- Concatenate attributes into a JSON formatted string for New Relic parsing
  return "{" .. table.concat(attributes, ",") .. "}"
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
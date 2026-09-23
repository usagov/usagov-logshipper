-- Gets drupal record and returns a record with a json string of the drupal attributes.

-- Expects the following format:
-- [
--  drupal "base_url":"@base_url","severity":"@severity","type":"@type","date":"@date",
--  "uid":"@uid","request_uri":"@request_uri","refer":"@referer","ip":"@ip",
--  "link":"@link","message":"@message"
-- ]

-- The keys above, in the order the format string emits them. Drupal interpolates
-- the values raw, so a quote, a backslash or a control character in any of them
-- breaks the JSON this transform hands to New Relic.
local DRUPAL_FIELDS = {
    "base_url", "severity", "type", "date",
    "uid", "request_uri", "refer", "ip",
    "link", "message"
}

-- Escape a Lua string for inclusion in a JSON string literal.
-- Backslash must be escaped first, or it would double-escape the others.
local function json_escape(s)
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"', '\\"')
    s = s:gsub('%c', function(c) return string.format('\\u%04X', string.byte(c)) end)
    return s
end

-- Locate each `"<key>":"` marker. Splitting on the markers rather than on quotes
-- or commas is what keeps a quote inside a value from ending that value early.
local function find_field_markers(s)
    local markers = {}
    for _, key in ipairs(DRUPAL_FIELDS) do
        local from, to = s:find('"' .. key .. '":"', 1, true)
        if from then
            markers[#markers + 1] = { key = key, from = from, to = to }
        end
    end
    table.sort(markers, function (a, b) return a.from < b.from end)
    return markers
end

local drupal_attributes_json_string = function (orig_string)
    local markers = find_field_markers(orig_string)

    -- An unrecognised shape is passed through as it was, which is what this
    -- transform did for every input before.
    if #markers == 0 then
        return "{" .. orig_string .. "}"
    end

    local parts = {}
    for i, marker in ipairs(markers) do
        local value_end
        if markers[i + 1] then
            -- Back up over the `","` that separates this value from the next key.
            value_end = markers[i + 1].from - 3
        else
            -- Back up over the closing quote of the last value.
            value_end = #orig_string - 1
        end

        local value = ""
        if value_end >= marker.to + 1 then
            value = orig_string:sub(marker.to + 1, value_end)
        end

        parts[#parts + 1] = '"' .. marker.key .. '":"' .. json_escape(value) .. '"'
    end

    return "{" .. table.concat(parts, ",") .. "}"
end

-- The --luacheck:ignore comment suppresses a warning about setting
-- a global variable and that this is an unused function
-- (like most scripts, this function is called via fluentbit.conf,
--  which expects it to be defined in this way)
function parse_drupal_keys (_, timestamp, record) --luacheck: ignore
    if (record["drupal"] ~= nil) then
        record["drupal"] = drupal_attributes_json_string(record["drupal"])
    end
     -- 2 leaves timestamp unchanged
    return 2, timestamp, record
end

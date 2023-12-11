-- gets drupal record and returns a record with a json string of the drupal attributes
-- expects to following format:
-- [drupal "base_url":"@base_url","severity":"@severity","type":"@type","date":"@date","uid":"@uid","request_uri":"@request_uri","refer":"@referer","ip":"@ip","link":"@link","message":"@message"]

function parse_drupal_keys(tag, timestamp, record)
    if (record["drupal"] ~= nil) then
        record["drupal"] = drupal_attributes_json_string(record["drupal"])
    end
     -- 2 leaves timestamp unchanged
    return 2, timestamp, record
end

function drupal_attributes_json_string(orig_string)
    
    -- wrap drupal field in brackets to make it parsable json
    final_string = "{" .. orig_string .. "}"
    return final_string
end

-- TODO: escape special characters in message field
function escape_JSON_special_charaters(orig_string)
    local new_string = string.gsub(orig_string, "\\", "\\\\")
    new_string = string.gsub(new_string, "\"", "\\\"")
    new_string = string.gsub(new_string, "/", "\\/")
    new_string = string.gsub(new_string, "\b", "\\b")
    new_string = string.gsub(new_string, "\f", "\\f")
    new_string = string.gsub(new_string, "\n", "\\n")
    new_string = string.gsub(new_string, "\r", "\\r")
    new_string = string.gsub(new_string, "\t", "\\t")
    return new_string
end
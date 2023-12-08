-- gets drupal record and returns a record with a json string of the drupal attributes
function parse_keys_with_eq_pairs(tag, timestamp, record)
    print("record: ")
    print(record)
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
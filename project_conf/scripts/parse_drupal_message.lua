-- Parse a message from drupal.
-- Assumes this template format: [drupal base_url="@base_url", severity="@severity", type="@type", date="@date", uid="@uid", request_url="@request-uri", refer="@referer", ip="@ip", link="@link", message="@message"]

-- Splits a string of foo="bar" pairs and makes parsable json out of it. 
function parse_drupal_message(tag, timestamp, record)
   if record['drupal'] then
      -- The message is always the last element. It may contain all manner of unescaped content
      -- (with quotation marks around the whole thing), so we just look for message=".*" at  
      -- the end of the string.
      -- Then we'll grab the content between ' message="\' and the last quotation mark. 
      local msg_start, msg_end = string.find(record['drupal'], " message=\".*\"$")
      local msg_content_start = msg_start + 10
      local msg_content_end = msg_end - 1
      local drupal_message = record['drupal'].sub(msg_content_start, msg_content_end)

      -- The rest of the string is the part up to that pattern. Now we know exactly
      -- what to exclude. Note that we're retaining the trailing space before "message": 
      local drupal_rest = record['drupal'].sub(0, msg_start + 1)

      record['drupal_message'] = drupal_message
      record['drupal_rest'] = drupal_rest
      record['drupal_copy'] = record['drupal'] -- This is just here to reassure me that this block executed. 
    end
    -- 2 leaves timestamp unchanged
    return 2, timestamp, record
end

-- "[drupal base_url="https://cms-dev.usa.gov" severity="INFO" type="user" date="2023-11-30T17:11:05" uid="18" request-uri="https://cms-dev.usa.gov/saml/acs" refer="https://secureauth.gsa.gov/" ip="127.0.0.1" link="" message="Session opened for amy_farrell."]",

-- "drupal"=>"base_url="https://cms-dev.usa.gov" severity="INFO" type="user" date="2023-11-30T17:11:05" uid="18" request-uri="https://cms-dev.usa.gov/saml/acs" refer="https://secureauth.gsa.gov/" ip="127.0.0.1" link="" message="Session opened for amy_farrell."", "host"=>"gsa-tts-usagov.dev.cms", "ident"=>"aa06838d-a60d-4da7-9bf8-a26d358df09f", "ptype"=>"APP/PROC/WEB/0", "message"=>"[01-Dec-2023 01:11:05] WARNING: [pool www] child 424598 said into stdout: "[drupal base_url="https://cms-dev.usa.gov" severity="INFO" type="user" date="2023-11-30T17:11:05" uid="18" request-uri="https://cms-dev.usa.gov/saml/acs" refer="https://secureauth.gsa.gov/" ip="127.0.0.1" link="" message="Session opened for amy_farrell."]", "time"=>"2023-12-01T01:11:05.858816+00:00"}]

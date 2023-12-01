-- Parse a message from drupal.
-- Assumes this template format: TODO

-- Splits a string of foo="bar" pairs and makes parsable json out of it. 
function parse_drupal_message(tag, timestamp, record)
   if (tag ~= "drupal") then
      local drupal_message = 
        
   end
     -- 2 leaves timestamp unchanged
    return 2, timestamp, record
end

function eq_pairs_to_json_string(orig_string)
    local new_string = string.gsub(orig_string, "(%S+)=(%S+)", "\"%1\":%2,")
    -- trim off that last , and add curly braces around: 
    new_string = string.gsub(new_string, "(.+),$", "{%1}")
    return new_string
end    

-- "[drupal base_url="https://cms-dev.usa.gov" severity="INFO" type="user" date="2023-11-30T17:11:05" uid="18" request-uri="https://cms-dev.usa.gov/saml/acs" refer="https://secureauth.gsa.gov/" ip="127.0.0.1" link="" message="Session opened for amy_farrell."]",

-- "drupal"=>"base_url="https://cms-dev.usa.gov" severity="INFO" type="user" date="2023-11-30T17:11:05" uid="18" request-uri="https://cms-dev.usa.gov/saml/acs" refer="https://secureauth.gsa.gov/" ip="127.0.0.1" link="" message="Session opened for amy_farrell."", "host"=>"gsa-tts-usagov.dev.cms", "ident"=>"aa06838d-a60d-4da7-9bf8-a26d358df09f", "ptype"=>"APP/PROC/WEB/0", "message"=>"[01-Dec-2023 01:11:05] WARNING: [pool www] child 424598 said into stdout: "[drupal base_url="https://cms-dev.usa.gov" severity="INFO" type="user" date="2023-11-30T17:11:05" uid="18" request-uri="https://cms-dev.usa.gov/saml/acs" refer="https://secureauth.gsa.gov/" ip="127.0.0.1" link="" message="Session opened for amy_farrell."]", "time"=>"2023-12-01T01:11:05.858816+00:00"}]

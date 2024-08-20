-- Gets modsecurity record and returns a record with a json string of the modsecurity attributes.

local modsecurity_attributes_json_string = function (orig_string)
    -- Extract the ModSecurity text from the message
    local modsecurity_text = orig_string:match("ModSecurity:(.-)%[")

    -- Find text within square brackets and store in an array
    local i = 0;
    local attributes = {}
    for attribute in string.gmatch(orig_string, "%[(.-)%]") do

      -- Split attribute by whitespace
      local key, value = attribute:match("(%S+)%s+(.*)")
      if key and value then
          attribute = '"' .. key .. '":' .. value
      end
      if i == 0 then
        attribute = '"' .. attribute .. '":"' .. modsecurity_text .. '"'
      end
      table.insert(attributes, attribute)
      i = i + 1
    end

    -- Concatenate attributes into a JSON string
    local json_string = table.concat(attributes, ",")

    -- wrap modsecurity field in brackets to make it parsable json
    local final_string = "{" .. json_string .. "}"
    return final_string
  end

  -- The --luacheck:ignore comment suppresses a warning about setting
  -- a global variable and that this is an unused function
  -- (like most scripts, this function is called via fluentbit.conf,
  -- which expects it to be defined in this way)
  function parse_modsecurity_keys (_, timestamp, record) --luacheck: ignore
    if (record["message"] ~= nil) then
      record["message"] = modsecurity_attributes_json_string(record["message"])
    end
     -- 2 leaves timestamp unchanged
    return 2, timestamp, record
  end

  -- local input = {
  --   ["host"]="gsa-tts-usagov.prod.waf",
  --   ["ident"]="8fc602bd-ef1f-49af-9d93-792c095442a7",
  --   ["message"]="2024/08/19 09:22:57 [error] 3634#3634: *4670810 [client 140.238.241.117] ModSecurity: Access denied with code 400 (phase 2). Matched \"Operator `Eq' with parameter `0' against variable `REQBODY_ERROR' (Value: `1' ) [file \"/opt/owasp-crs/modsecurity.conf\"] [line \"60\"] [id \"200002\"] [rev \"\"] [msg \"Failed to parse request body.\"] [data \"Multipart parsing error: Multipart: Final boundary missing.\"] [severity \"2\"] [ver \"\"] [maturity \"0\"] [accuracy \"0\"] [hostname \"10.255.121.138\"] [uri \"/\"] [unique_id \"172405937735.197103\"] [ref \"v1276,1\"], client: 140.238.241.117, server: _, request: \"POST / HTTP/1.1\", host: \"waf-route-prod-usagov.app.cloud.gov\"",
  --   ["newrelic.source"]="api.logs",
  --   ["plugin.source"]="BARE-METAL",
  --   ["plugin.type"]="fluent-bit",
  --   ["plugin.version"]="2.0.0",
  --   ["pri"]="11",
  --   ["ptype"]="APP/PROC/WEB/1",
  --   ["raw_message"]="<11>1 2024-08-19T09:22:57.936601+00:00 gsa-tts-usagov.prod.waf 8fc602bd-ef1f-49af-9d93-792c095442a7 [APP/PROC/WEB/1] - [tags@47450 app_id=\"8fc602bd-ef1f-49af-9d93-792c095442a7\" app_name=\"waf\" deployment=\"cf-production\" index=\"e9142d48-5d18-4f21-a8ee-91d48a62cc84\" instance_id=\"1\" ip=\"10.10.1.9\" job=\"diego-cell\" organization_id=\"6bd8d843-2a5d-4011-b824-aa3db4d5bd22\" organization_name=\"gsa-tts-usagov\" origin=\"rep\" process_id=\"b3b909c8-fbaf-4576-affa-6aae38f54bda\" process_instance_id=\"5d7c34b2-a60a-4ad2-7674-7e18\" process_type=\"web\" source_id=\"8fc602bd-ef1f-49af-9d93-792c095442a7\" source_type=\"APP/PROC/WEB\" space_id=\"f717b614-a1ab-460e-bb50-6f3733700ea9\" space_name=\"prod\"] 2024/08/19 09:22:57 [error] 3634#3634: *4670810 [client 140.238.241.117] ModSecurity: Access denied with code 400 (phase 2). Matched \"Operator `Eq' with parameter `0' against variable `REQBODY_ERROR' (Value: `1' ) [file \"/opt/owasp-crs/modsecurity.conf\"] [line \"60\"] [id \"200002\"] [rev \"\"] [msg \"Failed to parse request body.\"] [data \"Multipart parsing error: Multipart: Final boundary missing.\"] [severity \"2\"] [ver \"\"] [maturity \"0\"] [accuracy \"0\"] [hostname \"10.255.121.138\"] [uri \"/\"] [unique_id \"172405937735.197103\"] [ref \"v1276,1\"], client: 140.238.241.117, server: _, request: \"POST / HTTP/1.1\", host: \"waf-route-prod-usagov.app.cloud.gov\"",
  --   ["tags.app_id"]="8fc602bd-ef1f-49af-9d93-792c095442a7",
  --   ["tags.app_name"]="waf",
  --   ["tags.deployment"]="cf-production",
  --   ["tags.index"]="e9142d48-5d18-4f21-a8ee-91d48a62cc84",
  --   ["tags.instance_id"]="1",
  --   ["tags.ip"]="10.10.1.9",
  --   ["tags.job"]="diego-cell",
  --   ["tags.organization_id"]="6bd8d843-2a5d-4011-b824-aa3db4d5bd22",
  --   ["tags.organization_name"]="gsa-tts-usagov",
  --   ["tags.origin"]="rep",
  --   ["tags.process_id"]="b3b909c8-fbaf-4576-affa-6aae38f54bda",
  --   ["tags.process_instance_id"]="5d7c34b2-a60a-4ad2-7674-7e18",
  --   ["tags.process_type"]="web",
  --   ["tags.source_id"]="8fc602bd-ef1f-49af-9d93-792c095442a7",
  --   ["tags.source_type"]="APP/PROC/WEB",
  --   ["tags.space_id"]="f717b614-a1ab-460e-bb50-6f3733700ea9",
  --   ["tags.space_name"]="prod",
  --   ["time"]="2024-08-19T09:22:57.936601+00:00",
  --   ["timestamp"]=1724059377936
  -- }

  -- local output = modsecurity_attributes_json_string(input['message'])
  -- print(input)
  -- print(output)
docker run --rm -i \
  -v "$PWD":/w:ro nickblah/lua:5.4-alpine \
  lua /w/dev-utils/modsec-test/test-harness.lua /w/project_conf/scripts/parse_modsecurity_keys.lua /w/dev-utils/modsec-test/test-corpus.txt \
  | while read -r l; do printf '%s' "$l" | jq -e . >/dev/null \
      && echo "valid  $(printf '%s' "$l" | jq -r .id)" \
      || echo "INVALID"; done


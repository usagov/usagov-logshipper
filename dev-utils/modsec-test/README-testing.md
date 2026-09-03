# Drafted replacement for parse_modsecurity_keys.lua

Fixes ModSecurity records arriving in New Relic with attributes missing.

Two distinct triggers, both confirmed against real captured log lines:

1. **Unescaped backslashes.** The current script escapes `"` but not `\`.
   ModSecurity renders non-printable bytes as `\xNN`, and `\x` is not a
   valid JSON escape, so the emitted string is invalid JSON. Confirmed on
   the real dev 200002 line (`Invalid escape at column 384`) and on prod's
   200003 multipart-flag line (`Invalid escape at column 450`). **This one
   predates the CRS rollout and is affecting production today** -- every
   200003 record carries `\x0a` separators. CRS amplifies it because most
   `@rx` regexes contain `\d`, `\s`, `\b`.
2. **Character classes mistaken for fields.** `%[(.-)%]` matches `[^>]*` or
   `[\s\S]` inside a regex as though it were a `[key "value"]` field,
   shifting or destroying the real ones. Observed on dev 2026-08-27: 4 of
   19 detections arrived with empty `Modsecurity.id`/`.msg`.

New Relic's handling of invalid JSON is inconsistent -- prod's 200003 is
salvaged while dev's 200002 lost everything after the bad escape -- so the
attributes cannot be relied on until the JSON is well-formed.

## What changed

1. **Bracketed fields matched by shape, not by any `[...]`.**
   Now `%[([%w_]+)%s"([^"]*)"%]` — a bare word, a space, a double-quoted
   value. Character classes inside a regex never take that shape, so they
   are no longer mistaken for fields.
2. **Message no longer cut at the first `[`.** It is cut at the first
   *genuine* field (`[word "`), so `@rx` messages survive intact.
3. **Proper JSON escaping.** Backslashes are escaped (previously not, so
   `\b`/`\d`/`\s` in regexes became JSON escapes and corrupted the value),
   as are control characters. Keys are escaped too; previously only values
   were, which is how unescaped quotes ended up in key positions.
4. **Repeated keys joined instead of duplicated.** CRS rules carry many
   `[tag "..."]`; the old output emitted duplicate `"tag"` keys and all but
   the last were discarded. Now joined with commas.
5. **Trailer scanned only from `, client:` onward**, so commas inside a
   regex or inside `[data "..."]` cannot invent keys.
6. **`level` anchored to the nginx timestamp prefix**, so a bare `[word]`
   inside a regex cannot be mistaken for the log level.

Attribute names are unchanged. Verified no key produced by the current
parser is missing from the new one.

## Running the tests

    docker run --rm -i \
      -v "$PWD":/w:ro nickblah/lua:5.4-alpine \
      lua /w/dev-utils/modsec-test/test-harness.lua /w/project_conf/scripts/parse_modsecurity_keys.lua /w/dev-utils/modsec-test/test-corpus.txt \
      | while read -r l; do printf '%s' "$l" | jq -e . >/dev/null \
          && echo "valid  $(printf '%s' "$l" | jq -r .id)" \
          || echo "INVALID"; done

Expected: 8/8 valid. The current parser manages 4/8, failing lines 2, 6,
7 and 8.

`test-corpus.txt` lines 1, 7 and 8 are real captured lines (dev 920170,
dev 200002, prod 200003). The rest are constructed to cover bracket-heavy
regexes, backslashes, repeated tags, and a `]` inside `[data "..."]`.

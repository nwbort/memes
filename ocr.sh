#!/usr/bin/env bash
set -euo pipefail

API_KEY="K83735237388957"

for img in meme*.jpg; do
  base="${img%.jpg}"
  out="${base}.txt"
  if [ -f "$out" ] && [ -s "$out" ]; then
    echo "SKIP $out"
    continue
  fi

  b64="data:image/jpeg;base64,$(base64 -w 0 "$img")"

  response=$(curl -s https://api.ocr.space/parse/image \
    -H "apikey: $API_KEY" \
    --data-urlencode "base64Image=$b64" \
    --data "language=eng&isOverlayRequired=false&scale=true&OCREngine=2")

  text=$(echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('ParsedResults') or []
print('\n'.join(r.get('ParsedText','') for r in results).strip())
")

  if [ -n "$text" ]; then
    echo "$text" > "$out"
    echo "OK $out"
  else
    echo "EMPTY $img"
    err=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ErrorMessage','unknown'))" 2>/dev/null || true)
    [ -n "$err" ] && echo "  error: $err"
  fi
done

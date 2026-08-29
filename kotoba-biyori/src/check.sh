#!/bin/bash
W="$(dirname "$0")"; bad=0
for f in "$W"/d[0-9][0-9].js; do
  n=$(basename "$f" .js)
  w=$(grep -c '^      { ja: .*[^}],$' "$f")
  b=$(grep -c '^      { ja: .*note: .*},\?$' "$f")
  q=$(grep -c '{ q: ' "$f")
  e=$(grep -c '{ s: ' "$f")
  hs=$(grep -nP '\{ s: "[^"]*\p{Hangul}' "$f" | head -2)
  hj=$(grep -nP '(\{|  )ja: "[^"]*\p{Hangul}' "$f" | head -2)
  hk=$(grep -nP 'kana: "[^"]*\p{Hangul}' "$f" | head -2)
  et=$(grep -nP ', t: "\s*" \}' "$f" | head -2)
  printf '%s 단어:%2d 확장:%d 예문:%2d 퀴즈:%d' "$n" "$w" "$b" "$e" "$q"
  m=""
  [ "$w" -ne 10 ] && { m="$m [단어≠10]"; bad=1; }
  [ "$b" -ne 6 ] && { m="$m [확장≠6]"; bad=1; }
  [ "$q" -ne 6 ] && { m="$m [퀴즈≠6]"; bad=1; }
  [ "$e" -lt 20 ] && { m="$m [예문<20]"; bad=1; }
  [ -n "$hs" ] && { m="$m [예문에 한글]"; bad=1; }
  [ -n "$hj" ] && { m="$m [표제어에 한글]"; bad=1; }
  [ -n "$hk" ] && { m="$m [かな에 한글]"; bad=1; }
  [ -n "$et" ] && { m="$m [번역 빔]"; bad=1; }
  echo "$m"
  for v in "$hs" "$hj" "$hk" "$et"; do [ -n "$v" ] && echo "$v"; done
done
echo "---"; [ $bad -eq 0 ] && echo "점검 통과" || echo "문제 있음"

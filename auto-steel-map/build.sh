#!/bin/sh
# data.js, app.html, img/*.webp 를 합쳐 파일 하나로 열리는 자동차부품지도.html 을 만든다.
cd "$(dirname "$0")" && python3 - <<'PY'
import base64, glob, json, os
app = open("app.html", encoding="utf-8").read()
data = open("data.js", encoding="utf-8").read()
imgs = {os.path.basename(f)[:-5]: "data:image/webp;base64," + base64.b64encode(open(f, "rb").read()).decode()
        for f in sorted(glob.glob("img/*.webp"))}
assert "/*@@DATA@@*/" in app and "/*@@IMG@@*/" in app
out = app.replace("/*@@DATA@@*/", data).replace("/*@@IMG@@*/", "const IMG_SRC = " + json.dumps(imgs) + ";")
OUT = "자동차부품지도.html"
open(OUT, "w", encoding="utf-8").write(out)
# 웹 주소(폴더)로 열었을 때 본 파일로 넘겨 주는 짧은 index.html
open("index.html", "w", encoding="utf-8").write(
  '<!doctype html><meta charset="utf-8"><title>자동차부품지도</title>'
  '<meta http-equiv="refresh" content="0; url=%EC%9E%90%EB%8F%99%EC%B0%A8%EB%B6%80%ED%92%88%EC%A7%80%EB%8F%84.html">'
  '<p><a href="자동차부품지도.html">자동차부품지도 열기</a></p>')
print("%s 생성 완료 (그림 %d장, %d KB)" % (OUT, len(imgs), os.path.getsize(OUT) // 1024))
PY

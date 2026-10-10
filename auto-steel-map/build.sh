#!/bin/sh
# data.js, app.html, img/*.webp 를 합쳐 파일 하나로 열리는 index.html 을 만든다.
cd "$(dirname "$0")" && python3 - <<'PY'
import base64, glob, json, os
app = open("app.html", encoding="utf-8").read()
data = open("data.js", encoding="utf-8").read()
imgs = {os.path.basename(f)[:-5]: "data:image/webp;base64," + base64.b64encode(open(f, "rb").read()).decode()
        for f in sorted(glob.glob("img/*.webp"))}
assert "/*@@DATA@@*/" in app and "/*@@IMG@@*/" in app
out = app.replace("/*@@DATA@@*/", data).replace("/*@@IMG@@*/", "const IMG_SRC = " + json.dumps(imgs) + ";")
open("index.html", "w", encoding="utf-8").write(out)
print("index.html 생성 완료 (그림 %d장, %d KB)" % (len(imgs), os.path.getsize("index.html") // 1024))
PY

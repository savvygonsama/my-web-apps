#!/bin/sh
# data.js 와 app.html 을 합쳐 파일 하나로 열리는 index.html 을 만든다.
cd "$(dirname "$0")" && python3 - <<'PY'
app = open("app.html", encoding="utf-8").read()
data = open("data.js", encoding="utf-8").read()
assert "/*@@DATA@@*/" in app
open("index.html", "w", encoding="utf-8").write(app.replace("/*@@DATA@@*/", data))
print("index.html 생성 완료")
PY
